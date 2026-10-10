-- Миграция: начальная схема базы данных «Моё дело»
-- Выполняется автоматически через GORM AutoMigrate, но можно и вручную

-- Таблица пользователей
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'executor')),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) DEFAULT '',
    rating DECIMAL(3,2) DEFAULT 5.00,
    skills TEXT DEFAULT '',
    lat DECIMAL(10,8) DEFAULT 0,
    lon DECIMAL(11,8) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Таблица заказов
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    executor_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) DEFAULT 'Прочее',
    priority INTEGER DEFAULT 3 CHECK (priority BETWEEN 1 AND 3),
    address VARCHAR(500) NOT NULL,
    lat DECIMAL(10,8) DEFAULT 0,
    lon DECIMAL(11,8) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Таблица отзывов
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    executor_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    customer_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
    comment TEXT DEFAULT '',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблица документов
CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    doc_type VARCHAR(50) NOT NULL CHECK (doc_type IN ('passport', 'snils', 'bank', 'parent_consent')),
    file_path VARCHAR(500) NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_executor ON orders(executor_id);
CREATE INDEX IF NOT EXISTS idx_orders_lat_lon ON orders(lat, lon);
CREATE INDEX IF NOT EXISTS idx_reviews_executor ON reviews(executor_id);
CREATE INDEX IF NOT EXISTS idx_documents_user ON documents(user_id);
