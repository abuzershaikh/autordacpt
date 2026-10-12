-- ========================================================
-- Ride AutoAccept Enterprise Control Engine Database Schema
-- Optimized for High Throughput, Indexed for Fast Pagination
-- ========================================================

-- 1. Users Table (Cached & Synced from Cloud Firestore)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(128) PRIMARY KEY, -- Firebase Auth UID
    phone VARCHAR(25) NOT NULL,
    display_name VARCHAR(100) DEFAULT 'Driver Partner',
    email VARCHAR(120) NULL,
    device_brand VARCHAR(50) DEFAULT 'Samsung',
    device_model VARCHAR(50) DEFAULT 'SM-M145F',
    android_version VARCHAR(20) DEFAULT '15',
    plan_id VARCHAR(50) DEFAULT 'none',
    plan_name VARCHAR(100) DEFAULT 'Free Trial',
    plan_status ENUM('active', 'inactive', 'expired') DEFAULT 'inactive',
    plan_expires_at DATETIME NULL,
    free_rides_used INT DEFAULT 0,
    free_rides_limit INT DEFAULT 2,
    is_accessibility_enabled BOOLEAN DEFAULT FALSE,
    is_online BOOLEAN DEFAULT FALSE,
    min_fare DECIMAL(10,2) DEFAULT 40.00,
    max_fare DECIMAL(10,2) DEFAULT 2000.00,
    max_pickup_distance DECIMAL(6,2) DEFAULT 5.00,
    max_trip_distance DECIMAL(6,2) DEFAULT 30.00,
    auto_accept_enabled BOOLEAN DEFAULT TRUE,
    click_speed VARCHAR(20) DEFAULT 'instant',
    last_ping_at DATETIME NULL,
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone),
    INDEX idx_plan_status (plan_status),
    INDEX idx_online (is_online),
    INDEX idx_joined_at (joined_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Rides Telemetry Table (Live Orders & Click Performance)
CREATE TABLE IF NOT EXISTS rides (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL,
    service ENUM('porter', 'rapido', 'ola', 'uber') NOT NULL,
    status ENUM('accepted', 'missed', 'rejected', 'filtered') NOT NULL,
    fare DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    pickup_distance DECIMAL(6, 2) DEFAULT 0.00,
    trip_distance DECIMAL(6, 2) DEFAULT 0.00,
    user_min_fare DECIMAL(10, 2) DEFAULT 0.00,
    user_max_fare DECIMAL(10, 2) DEFAULT 0.00,
    user_max_pickup DECIMAL(6, 2) DEFAULT 0.00,
    user_max_trip DECIMAL(6, 2) DEFAULT 0.00,
    response_time_ms INT DEFAULT 0, -- Auto-click physical delay in ms
    reason VARCHAR(255) NULL,
    order_id VARCHAR(100) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_rides (user_id, created_at),
    INDEX idx_service_status (service, status),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. App Crashlytics Table (Exception Stack Traces & Errors)
CREATE TABLE IF NOT EXISTS crashes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(128) NULL,
    error_message TEXT NOT NULL,
    stack_trace LONGTEXT NULL,
    screen_name VARCHAR(100) NULL,
    device_brand VARCHAR(50) NULL,
    device_model VARCHAR(50) NULL,
    os_version VARCHAR(30) NULL,
    app_version VARCHAR(30) DEFAULT '1.0.0',
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_crash (user_id),
    INDEX idx_resolved (is_resolved),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. YouTube Tutorials Table (Managed Remotely via VPS Panel)
CREATE TABLE IF NOT EXISTS tutorials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT NULL,
    youtube_url VARCHAR(255) NOT NULL,
    youtube_id VARCHAR(50) NOT NULL,
    thumbnail_url VARCHAR(255) NULL,
    category ENUM('general', 'ola', 'rapido', 'porter', 'uber', 'troubleshooting') DEFAULT 'general',
    order_index INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_order (order_index),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Remote App Settings & Dynamic Free Rides Control
CREATE TABLE IF NOT EXISTS app_settings (
    setting_key VARCHAR(60) PRIMARY KEY,
    setting_value TEXT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. App Version Control & Remote Fleet Releases Table
CREATE TABLE IF NOT EXISTS app_versions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version_name VARCHAR(50) NOT NULL,
    version_code INT NOT NULL UNIQUE,
    download_url TEXT NULL,
    is_force_update BOOLEAN DEFAULT FALSE,
    is_blocked BOOLEAN DEFAULT FALSE,
    update_title VARCHAR(200) DEFAULT 'New Update Available',
    update_message TEXT NULL,
    release_notes TEXT NULL,
    device_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_version_code (version_code),
    INDEX idx_blocked (is_blocked)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed Default Settings & Version Control
INSERT INTO app_settings (setting_key, setting_value) 
VALUES 
    ('free_rides_limit', '2'),
    ('announcement_text', 'Welcome to Ride AutoAccept! Configure your filters and start earning.'),
    ('announcement_active', '1'),
    ('min_app_version', '1.0.0'),
    ('min_version_code', '1'),
    ('latest_version_code', '1'),
    ('latest_version_name', '1.0.0'),
    ('global_force_update', '0'),
    ('global_download_url', 'http://65.20.77.112:5000/download/latest.apk'),
    ('global_update_title', '🚀 Naya Update Aaya Hai!'),
    ('global_update_message', 'Purana version band ho gaya hai. Auto-accept continue rakhne ke liye abhi naya version install karein.')
ON DUPLICATE KEY UPDATE setting_key = setting_key;

INSERT INTO app_versions (version_name, version_code, download_url, is_force_update, is_blocked, update_title, update_message, release_notes)
VALUES ('1.0.0', 1, 'http://65.20.77.112:5000/download/latest.apk', FALSE, FALSE, 'Ride AutoAccept v1.0.0', 'Initial Production Release', 'Auto-accept for Rapido, Porter, Ola & Uber')
ON DUPLICATE KEY UPDATE version_code = version_code;

-- Seed Initial High-Quality Tutorials (Default Starter Guides)
INSERT INTO tutorials (title, description, youtube_url, youtube_id, thumbnail_url, category, order_index, is_active)
VALUES 
    (
        'Complete App Setup & Permissions Guide',
        'Learn how to enable Accessibility service, Battery Unrestricted mode, and Display Over Other Apps permission for 0ms ultra-fast clicks.',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'dQw4w9WgXcQ',
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        'general',
        1,
        TRUE
    ),
    (
        'Ola Driver Instant Auto-Accept Tutorial',
        'How to configure Min/Max Fare and Trip Distance to automatically grab high-paying Ola Prime and Mini bookings.',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'dQw4w9WgXcQ',
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        'ola',
        2,
        TRUE
    ),
    (
        'Rapido Captain Auto Accept Setup',
        'How to accept Rapido bike and auto orders with human-like randomized touch response.',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'dQw4w9WgXcQ',
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        'rapido',
        3,
        TRUE
    ),
    (
        'Porter Driver Partner Instant Accept',
        'Porter pickup distance filtering and instant accept order tray tutorial.',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'dQw4w9WgXcQ',
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        'porter',
        4,
        TRUE
    ),
    (
        'Uber Driver Setup & Overlay Guide',
        'How to configure Uber auto-accept with floating overlay permission on Android 12, 13, 14 & 15.',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'dQw4w9WgXcQ',
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        'uber',
        5,
        TRUE
    )
ON DUPLICATE KEY UPDATE id = id;
