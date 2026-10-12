const fs = require('fs');
const path = require('path');

let Client;
try {
  Client = require('ssh2').Client;
} catch (e) {
  try {
    Client = require('d:/abuzer projects/Mail tracker for Gmail/email-tracker-server/node_modules/ssh2').Client;
  } catch (err) {
    console.error('ssh2 module not found locally. Run `npm install ssh2` or run deploy.sh directly on VPS.');
    process.exit(1);
  }
}

const VPS_CONFIG = {
  host: process.env.VPS_HOST || '65.20.77.112',
  port: parseInt(process.env.VPS_PORT || '22', 10),
  username: process.env.VPS_USER || 'root',
  password: process.env.VPS_PASSWORD || 'G8u$RW{5m46buXgw',
};

const LOCAL_DIR = path.resolve(__dirname, '../');
const REMOTE_DIR = '/opt/autoride-enterprise';

function runRemoteCommand(conn, cmd) {
  return new Promise((resolve, reject) => {
    conn.exec(cmd, (err, stream) => {
      if (err) return reject(err);
      let stdout = '';
      let stderr = '';
      stream.on('data', (data) => (stdout += data.toString()));
      stream.stderr.on('data', (data) => (stderr += data.toString()));
      stream.on('close', (code) => {
        resolve({ code, stdout, stderr });
      });
    });
  });
}

function sftpMkdir(sftp, remoteDir) {
  return new Promise((resolve) => {
    sftp.mkdir(remoteDir, (err) => resolve());
  });
}

function sftpUploadFile(sftp, localPath, remotePath) {
  return new Promise((resolve, reject) => {
    sftp.fastPut(localPath, remotePath, (err) => {
      if (err) return reject(err);
      resolve();
    });
  });
}

async function uploadDirectoryRecursive(sftp, localBase, remoteBase) {
  await sftpMkdir(sftp, remoteBase);
  const items = fs.readdirSync(localBase);

  for (const item of items) {
    if (item === 'node_modules' || item === '.git' || item === 'logs' || item.endsWith('.log')) {
      continue;
    }
    const localItemPath = path.join(localBase, item);
    const remoteItemPath = `${remoteBase}/${item}`;
    const stat = fs.statSync(localItemPath);

    if (stat.isDirectory()) {
      await sftpMkdir(sftp, remoteItemPath);
      await uploadDirectoryRecursive(sftp, localItemPath, remoteItemPath);
    } else {
      await sftpUploadFile(sftp, localItemPath, remoteItemPath);
    }
  }
}

async function deploy() {
  console.log('====================================================');
  console.log(`🚀 Starting Auto-Deploy to VPS (${VPS_CONFIG.host})...`);
  console.log('====================================================');

  const conn = new Client();

  return new Promise((resolve, reject) => {
    conn
      .on('ready', async () => {
        try {
          console.log('[1/5] Connected to VPS. Creating remote directory ' + REMOTE_DIR);
          await runRemoteCommand(conn, `mkdir -p ${REMOTE_DIR}`);

          console.log('[2/5] Uploading project files via SFTP...');
          await new Promise((resSftp, rejSftp) => {
            conn.sftp(async (err, sftp) => {
              if (err) return rejSftp(err);
              try {
                await uploadDirectoryRecursive(sftp, LOCAL_DIR, REMOTE_DIR);
                console.log('✓ Files uploaded successfully!');
                resSftp();
              } catch (e) {
                rejSftp(e);
              }
            });
          });

          console.log('[3/5] Installing production npm dependencies on VPS...');
          const npmRes = await runRemoteCommand(conn, `cd ${REMOTE_DIR} && npm install --production`);
          console.log(npmRes.stdout.slice(0, 300));

          console.log('[4/5] Executing database migration on MariaDB/MySQL...');
          const migRes = await runRemoteCommand(conn, `cd ${REMOTE_DIR} && npm run migrate`);
          console.log(migRes.stdout);

          console.log('[5/5] Reloading PM2 process (autoride-vps-engine)...');
          await runRemoteCommand(conn, 'firewall-cmd --add-port=5000/tcp --permanent && firewall-cmd --reload || true');
          const pm2Res = await runRemoteCommand(
            conn,
            `cd ${REMOTE_DIR} && pm2 delete autoride-vps-engine 2>/dev/null || true; cd ${REMOTE_DIR} && pm2 start deploy/ecosystem.config.cjs && pm2 save`
          );
          console.log(pm2Res.stdout);

          console.log('\n====================================================');
          console.log('✅ Enterprise Deployment Complete on VPS!');
          console.log('🌐 Web Control Panel: http://65.20.77.112:5000');
          console.log('💳 Razorpay Webhook:  http://65.20.77.112:5000/api/payment/webhook');
          console.log('📱 Mobile Plans API:  http://65.20.77.112:5000/api/payment/plans');
          console.log('====================================================');

          conn.end();
          resolve();
        } catch (err) {
          conn.end();
          reject(err);
        }
      })
      .on('error', reject)
      .connect(VPS_CONFIG);
  });
}

deploy().catch((err) => {
  console.error('❌ Deployment Error:', err);
  process.exit(1);
});
