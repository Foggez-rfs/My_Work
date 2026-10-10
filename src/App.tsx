import { useState, useEffect, createContext, useContext, ReactNode } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

// ==================== ТИПЫ ====================
interface User {
  id: number;
  phone: string;
  role: 'customer' | 'executor';
  first_name: string;
  rating: number;
}

interface Order {
  id: number;
  customer_id: number;
  executor_id: number | null;
  description: string;
  category: string;
  priority: number;
  address: string;
  lat: number;
  lon: number;
  status: 'pending' | 'accepted' | 'completed' | 'cancelled';
  created_at: string;
  customer_name?: string;
  executor_name?: string;
  rating?: number;
}

// ==================== ИИ-КЛАССИФИКАТОР ====================
const CATEGORIES: Record<string, string[]> = {
  'Сантехника 🔧': ['кран', 'труб', 'вода', 'слив', 'унитаз', 'сантехник', 'затоп'],
  'Электрика ⚡': ['электрик', 'розетк', 'провод', 'свет', 'лампочк', 'замыкает', 'ток'],
  'Уборка 🧹': ['убор', 'пылесос', 'мыть', 'чист', 'гряз', 'помыть', 'пол'],
  'Доставка 📦': ['достав', 'привез', 'купить', 'продукт', 'аптек', 'магазин', 'лекарств'],
  'Ремонт 🔨': ['ремонт', 'мебел', 'дверь', 'окно', 'повесить', 'сломал', 'починить'],
  'Сопровождение 🚶': ['сопровожд', 'помоч', 'дойти', 'поликлиник', 'больниц', 'прогулк'],
};

const URGENT_KEYWORDS = ['срочно', 'авария', 'затопило', 'прорвало', 'пожар', 'замыкает', 'беда'];

function classifyOrder(text: string): { category: string; priority: number } {
  const lower = text.toLowerCase();
  
  // Определяем приоритет
  let priority = 3;
  for (const keyword of URGENT_KEYWORDS) {
    if (lower.includes(keyword)) {
      priority = 1;
      break;
    }
  }
  
  // Определяем категорию
  let category = 'Прочее 📋';
  for (const [cat, keywords] of Object.entries(CATEGORIES)) {
    for (const keyword of keywords) {
      if (lower.includes(keyword)) {
        category = cat;
        break;
      }
    }
    if (category !== 'Прочее 📋') break;
  }
  
  return { category, priority };
}

// ==================== ГЕОПОИСК (Haversine) ====================
function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000; // Радиус Земли в метрах
  const toRad = (deg: number) => deg * Math.PI / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// ==================== ХРАНИЛИЩЕ (имитация БД) ====================
const STORAGE_KEY = 'moe_delo_data';

interface AppData {
  users: (User & { password: string })[];
  orders: Order[];
  nextUserId: number;
  nextOrderId: number;
}

function loadData(): AppData {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (raw) return JSON.parse(raw);
  
  // Начальные тестовые данные
  const initial: AppData = {
    users: [
      { id: 1, phone: '+79001112233', password: 'demo1', role: 'customer', first_name: 'Мария Ивановна', rating: 5.0 },
      { id: 2, phone: '+79004445566', password: 'demo2', role: 'executor', first_name: 'Алексей Петров', rating: 4.8 },
      { id: 3, phone: '+79007778899', password: 'demo3', role: 'executor', first_name: 'Дмитрий Сидоров', rating: 4.5 },
    ],
    orders: [
      { id: 1, customer_id: 1, executor_id: null, description: 'Прорвало кран на кухне, вода льётся', category: 'Сантехника 🔧', priority: 1, address: 'ул. Ленина, д. 15, кв. 3', lat: 55.7558, lon: 37.6173, status: 'pending', created_at: new Date().toISOString() },
      { id: 2, customer_id: 1, executor_id: 2, description: 'Нужно помочь дойти до поликлиники', category: 'Сопровождение 🚶', priority: 3, address: 'ул. Мира, д. 7, кв. 12', lat: 55.7560, lon: 37.6180, status: 'accepted', created_at: new Date(Date.now() - 86400000).toISOString(), customer_name: 'Мария Ивановна', executor_name: 'Алексей Петров' },
      { id: 3, customer_id: 1, executor_id: 3, description: 'Нужно купить продукты в магазине', category: 'Доставка 📦', priority: 3, address: 'пр. Победы, д. 22, кв. 5', lat: 55.7540, lon: 37.6150, status: 'completed', created_at: new Date(Date.now() - 172800000).toISOString(), customer_name: 'Мария Ивановна', executor_name: 'Дмитрий Сидоров', rating: 5 },
    ],
    nextUserId: 4,
    nextOrderId: 4,
  };
  localStorage.setItem(STORAGE_KEY, JSON.stringify(initial));
  return initial;
}

function saveData(data: AppData) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
}

// ==================== КОНТЕКСТЫ ====================
interface AuthContextType {
  user: User | null;
  token: string | null;
  login: (phone: string, password: string) => string | null;
  register: (phone: string, password: string, role: string, firstName: string) => string | null;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType>({
  user: null, token: null, login: () => null, register: () => null, logout: () => {}
});

interface ThemeContextType {
  dark: boolean;
  toggle: () => void;
}

const ThemeContext = createContext<ThemeContextType>({ dark: false, toggle: () => {} });

// ==================== КОМПОНЕНТЫ UI ====================

function StarRating({ score, onChange, size = 'md' }: { score: number; onChange?: (s: number) => void; size?: 'sm' | 'md' | 'lg' }) {
  const sizeClass = size === 'lg' ? 'text-4xl' : size === 'md' ? 'text-2xl' : 'text-lg';
  return (
    <div className="flex gap-1">
      {[1, 2, 3, 4, 5].map(s => (
        <span
          key={s}
          className={`${sizeClass} cursor-pointer transition-transform hover:scale-125 ${s <= score ? 'text-yellow-400' : 'text-gray-300 dark:text-gray-600'}`}
          onClick={() => onChange?.(s)}
        >
          ★
        </span>
      ))}
    </div>
  );
}

function PriorityBadge({ priority }: { priority: number }) {
  const colors = {
    1: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
    2: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
    3: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
  };
  const labels = { 1: '🔴 Срочно', 2: '🟡 Средний', 3: '🟢 Плановый' };
  return (
    <span className={`px-3 py-1 rounded-full text-sm font-semibold ${colors[priority as keyof typeof colors]}`}>
      {labels[priority as keyof typeof labels]}
    </span>
  );
}

function StatusBadge({ status }: { status: string }) {
  const config: Record<string, { color: string; label: string }> = {
    pending: { color: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200', label: '⏳ Ожидает' },
    accepted: { color: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200', label: '✅ Принят' },
    completed: { color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200', label: '✔️ Завершён' },
    cancelled: { color: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200', label: '❌ Отменён' },
  };
  const c = config[status] || config.pending;
  return <span className={`px-3 py-1 rounded-full text-sm font-semibold ${c.color}`}>{c.label}</span>;
}

// ==================== ЭКРАНЫ ====================

function LoginScreen({ onLogin }: { onLogin: () => void }) {
  const { login, register } = useContext(AuthContext);
  const [isRegister, setIsRegister] = useState(false);
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [role, setRole] = useState<'customer' | 'executor'>('customer');
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    
    if (isRegister) {
      if (!firstName.trim()) { setError('Введите имя'); return; }
      const err = register(phone, password, role, firstName);
      if (err) { setError(err); return; }
    } else {
      const err = login(phone, password);
      if (err) { setError(err); return; }
    }
    onLogin();
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-blue-50 to-blue-100 dark:from-slate-900 dark:to-slate-800">
      <motion.div 
        initial={{ opacity: 0, y: 20 }} 
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md"
      >
        <div className="text-center mb-8">
          <div className="text-6xl mb-4">🤝</div>
          <h1 className="text-3xl font-bold text-primary dark:text-blue-300">Моё дело</h1>
          <p className="text-large text-gray-600 dark:text-gray-300 mt-2">Помощь рядом с вами</p>
        </div>
        
        <div className="card">
          <h2 className="text-xlarge font-bold mb-6 text-center">
            {isRegister ? 'Регистрация' : 'Вход в систему'}
          </h2>
          
          <form onSubmit={handleSubmit} className="space-y-4">
            {isRegister && (
              <>
                <div>
                  <label className="block text-large font-medium mb-2">Ваше имя</label>
                  <input
                    type="text"
                    value={firstName}
                    onChange={e => setFirstName(e.target.value)}
                    className="w-full p-4 text-lg border-2 border-gray-200 dark:border-gray-600 rounded-xl bg-white dark:bg-slate-700 dark:text-white focus:border-primary focus:outline-none"
                    placeholder="Например: Мария Ивановна"
                  />
                </div>
                <div>
                  <label className="block text-large font-medium mb-2">Кто вы?</label>
                  <div className="grid grid-cols-2 gap-3">
                    <button
                      type="button"
                      onClick={() => setRole('customer')}
                      className={`btn-large ${role === 'customer' ? 'btn-primary' : 'btn-outline'}`}
                    >
                      👴 Мне нужна помощь
                    </button>
                    <button
                      type="button"
                      onClick={() => setRole('executor')}
                      className={`btn-large ${role === 'executor' ? 'btn-primary' : 'btn-outline'}`}
                    >
                      🙋 Хочу помогать
                    </button>
                  </div>
                </div>
              </>
            )}
            
            <div>
              <label className="block text-large font-medium mb-2">Телефон</label>
              <input
                type="tel"
                value={phone}
                onChange={e => setPhone(e.target.value)}
                className="w-full p-4 text-lg border-2 border-gray-200 dark:border-gray-600 rounded-xl bg-white dark:bg-slate-700 dark:text-white focus:border-primary focus:outline-none"
                placeholder="+7 (900) 123-45-67"
              />
            </div>
            
            <div>
              <label className="block text-large font-medium mb-2">Пароль</label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="w-full p-4 text-lg border-2 border-gray-200 dark:border-gray-600 rounded-xl bg-white dark:bg-slate-700 dark:text-white focus:border-primary focus:outline-none"
                placeholder="Введите пароль"
              />
            </div>
            
            {error && (
              <div className="p-3 bg-red-50 dark:bg-red-900/30 text-red-700 dark:text-red-300 rounded-xl text-large">
                ⚠️ {error}
              </div>
            )}
            
            <button type="submit" className="btn-large btn-primary w-full">
              {isRegister ? '✅ Зарегистрироваться' : '🔑 Войти'}
            </button>
          </form>
          
          <div className="mt-6 text-center">
            <button
              onClick={() => { setIsRegister(!isRegister); setError(''); }}
              className="text-large text-primary dark:text-blue-300 font-semibold underline"
            >
              {isRegister ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Зарегистрироваться'}
            </button>
          </div>
          
          {!isRegister && (
            <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/30 rounded-xl text-sm text-gray-600 dark:text-gray-300">
              <p className="font-semibold mb-1">Тестовые аккаунты:</p>
              <p>👴 Заказчик: +79001112233 / demo1</p>
              <p>🙋 Исполнитель: +79004445566 / demo2</p>
            </div>
          )}
        </div>
      </motion.div>
    </div>
  );
}

function CustomerScreen({ onNavigate }: { onNavigate: (screen: string) => void }) {
  const { user } = useContext(AuthContext);
  const data = loadData();
  const myOrders = data.orders.filter(o => o.customer_id === user?.id);

  return (
    <div className="p-4 max-w-lg mx-auto animate-fade-in">
      <div className="text-center mb-6">
        <h1 className="text-xlarge font-bold">Здравствуйте, {user?.first_name}!</h1>
        <p className="text-gray-600 dark:text-gray-300 text-large mt-1">Чем можем помочь?</p>
      </div>
      
      {/* Большая кнопка создания заказа */}
      <motion.button
        whileTap={{ scale: 0.95 }}
        onClick={() => onNavigate('new_order')}
        className="btn-large btn-danger w-full text-xl mb-6 py-8"
      >
        📝 Оформить заказ на помощь
      </motion.button>
      
      {/* Быстрые категории */}
      <div className="mb-6">
        <h2 className="text-large font-semibold mb-3">Быстрый заказ:</h2>
        <div className="grid grid-cols-3 gap-3">
          {[
            { icon: '🔧', label: 'Сантехника', desc: 'Кран, трубы' },
            { icon: '⚡', label: 'Электрика', desc: 'Розетки, свет' },
            { icon: '🧹', label: 'Уборка', desc: 'Помыть, почистить' },
            { icon: '📦', label: 'Доставка', desc: 'Продукты, аптека' },
            { icon: '🔨', label: 'Ремонт', desc: 'Мебель, двери' },
            { icon: '🚶', label: 'Сопроводить', desc: 'Поликлиника' },
          ].map(item => (
            <button
              key={item.label}
              onClick={() => onNavigate('new_order')}
              className="card text-center p-3 hover:border-primary transition-colors cursor-pointer"
            >
              <div className="text-3xl mb-1">{item.icon}</div>
              <div className="text-sm font-semibold">{item.label}</div>
              <div className="text-xs text-gray-500 dark:text-gray-400">{item.desc}</div>
            </button>
          ))}
        </div>
      </div>
      
      {/* Мои заказы */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-large font-semibold">Мои заказы</h2>
          <button onClick={() => onNavigate('my_orders')} className="text-primary dark:text-blue-300 font-semibold text-lg">
            Все →
          </button>
        </div>
        {myOrders.length === 0 ? (
          <div className="card text-center py-8 text-gray-500 dark:text-gray-400">
            <div className="text-4xl mb-2">📋</div>
            <p className="text-large">Заказов пока нет</p>
            <p className="text-sm mt-1">Нажмите «Оформить заказ» выше</p>
          </div>
        ) : (
          <div className="space-y-3">
            {myOrders.slice(0, 3).map(order => (
              <div key={order.id} className="card">
                <div className="flex items-start justify-between mb-2">
                  <span className="text-xl">{order.category.split(' ')[1]}</span>
                  <StatusBadge status={order.status} />
                </div>
                <p className="text-large font-medium">{order.description}</p>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">📍 {order.address}</p>
                <div className="flex items-center justify-between mt-2">
                  <PriorityBadge priority={order.priority} />
                  <span className="text-xs text-gray-400">
                    {new Date(order.created_at).toLocaleDateString('ru-RU')}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function NewOrderScreen({ onBack }: { onBack: () => void }) {
  const { user } = useContext(AuthContext);
  const [description, setDescription] = useState('');
  const [address, setAddress] = useState('');
  const [classification, setClassification] = useState<{ category: string; priority: number } | null>(null);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    if (description.length > 3) {
      setClassification(classifyOrder(description));
    } else {
      setClassification(null);
    }
  }, [description]);

  const handleSubmit = () => {
    if (!description.trim() || !address.trim()) return;
    
    const data = loadData();
    const cls = classifyOrder(description);
    const newOrder: Order = {
      id: data.nextOrderId,
      customer_id: user!.id,
      executor_id: null,
      description,
      category: cls.category,
      priority: cls.priority,
      address,
      lat: 55.7558 + (Math.random() - 0.5) * 0.01,
      lon: 37.6173 + (Math.random() - 0.5) * 0.01,
      status: 'pending',
      created_at: new Date().toISOString(),
      customer_name: user!.first_name,
    };
    data.orders.push(newOrder);
    data.nextOrderId++;
    saveData(data);
    setSuccess(true);
  };

  if (success) {
    return (
      <div className="p-4 max-w-lg mx-auto animate-fade-in">
        <div className="card text-center py-12">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: 'spring', stiffness: 200 }}
          >
            <div className="text-6xl mb-4">✅</div>
            <h2 className="text-xlarge font-bold mb-2">Заказ создан!</h2>
            <p className="text-large text-gray-600 dark:text-gray-300 mb-2">
              Категория: {classification?.category}
            </p>
            <p className="text-gray-500 dark:text-gray-400 mb-6">
              Исполнители рядом получат уведомление
            </p>
          </motion.div>
          <button onClick={onBack} className="btn-large btn-primary w-full">
            ← Вернуться на главную
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4 max-w-lg mx-auto animate-fade-in">
      <button onClick={onBack} className="text-large text-primary dark:text-blue-300 font-semibold mb-4 flex items-center gap-2">
        ← Назад
      </button>
      
      <h1 className="text-xlarge font-bold mb-6">📝 Новый заказ</h1>
      
      <div className="space-y-4">
        <div>
          <label className="block text-large font-medium mb-2">
            Опишите, что нужно сделать
          </label>
          <textarea
            value={description}
            onChange={e => setDescription(e.target.value)}
            className="w-full p-4 text-lg border-2 border-gray-200 dark:border-gray-600 rounded-xl bg-white dark:bg-slate-700 dark:text-white focus:border-primary focus:outline-none min-h-[120px] resize-none"
            placeholder="Например: Прорвало кран на кухне, вода льётся. Нужно срочно починить."
          />
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            Пишите простыми словами — система поймёт
          </p>
        </div>
        
        {/* Показываем результат классификации */}
        {classification && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="card bg-blue-50 dark:bg-blue-900/30 border-blue-200 dark:border-blue-700"
          >
            <p className="text-sm font-semibold text-blue-800 dark:text-blue-200 mb-2">
              🤖 ИИ определил:
            </p>
            <div className="flex items-center gap-3">
              <span className="text-large font-bold">{classification.category}</span>
              <PriorityBadge priority={classification.priority} />
            </div>
          </motion.div>
        )}
        
        <div>
          <label className="block text-large font-medium mb-2">
            📍 Ваш адрес
          </label>
          <input
            type="text"
            value={address}
            onChange={e => setAddress(e.target.value)}
            className="w-full p-4 text-lg border-2 border-gray-200 dark:border-gray-600 rounded-xl bg-white dark:bg-slate-700 dark:text-white focus:border-primary focus:outline-none"
            placeholder="Улица, дом, квартира"
          />
        </div>
        
        <button
          onClick={handleSubmit}
          disabled={!description.trim() || !address.trim()}
          className="btn-large btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed"
        >
          📨 Отправить заказ
        </button>
      </div>
    </div>
  );
}

function ExecutorScreen({ onNavigate }: { onNavigate: (screen: string) => void }) {
  const { user } = useContext(AuthContext);
  const data = loadData();
  
  // Показываем заказы рядом (в радиусе 1 км от условной точки)
  const executorLat = 55.7558;
  const executorLon = 37.6173;
  
  const nearbyOrders = data.orders
    .filter(o => o.status === 'pending')
    .map(o => ({
      ...o,
      distance: haversine(executorLat, executorLon, o.lat, o.lon)
    }))
    .filter(o => o.distance <= 5000) // 5 км для демо
    .sort((a, b) => a.priority - b.priority || a.distance - b.distance);

  const myActiveOrders = data.orders.filter(
    o => o.executor_id === user?.id && (o.status === 'accepted' || o.status === 'pending')
  );

  const acceptOrder = (orderId: number) => {
    const data = loadData();
    const order = data.orders.find(o => o.id === orderId);
    if (order) {
      order.executor_id = user!.id;
      order.status = 'accepted';
      order.executor_name = user!.first_name;
      saveData(data);
      onNavigate('executor'); // Перерисовать
    }
  };

  return (
    <div className="p-4 max-w-lg mx-auto animate-fade-in">
      <div className="text-center mb-6">
        <h1 className="text-xlarge font-bold">Заказы рядом с вами</h1>
        <p className="text-gray-600 dark:text-gray-300 text-large mt-1">
          {nearbyOrders.length} заказов в радиусе 5 км
        </p>
      </div>
      
      {/* Мои активные заказы */}
      {myActiveOrders.length > 0 && (
        <div className="mb-6">
          <h2 className="text-large font-semibold mb-3">🎯 Ваши активные заказы:</h2>
          <div className="space-y-3">
            {myActiveOrders.map(order => (
              <div key={order.id} className="card border-l-4 border-l-purple-500">
                <div className="flex items-start justify-between mb-2">
                  <span className="text-xl">{order.category.split(' ')[1]}</span>
                  <StatusBadge status={order.status} />
                </div>
                <p className="text-large font-medium">{order.description}</p>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                  👤 {order.customer_name} • 📍 {order.address}
                </p>
                <div className="mt-3">
                  <button
                    onClick={() => {
                      const d = loadData();
                      const o = d.orders.find(x => x.id === order.id);
                      if (o) { o.status = 'completed'; saveData(d); onNavigate('executor'); }
                    }}
                    className="btn-large btn-success w-full"
                  >
                    ✅ Завершить заказ
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
      
      {/* Доступные заказы */}
      <h2 className="text-large font-semibold mb-3">📋 Доступные заказы:</h2>
      {nearbyOrders.length === 0 ? (
        <div className="card text-center py-8 text-gray-500 dark:text-gray-400">
          <div className="text-4xl mb-2">🔍</div>
          <p className="text-large">Нет заказов рядом</p>
          <p className="text-sm mt-1">Проверьте позже</p>
        </div>
      ) : (
        <div className="space-y-3">
          {nearbyOrders.map(order => (
            <motion.div
              key={order.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="card"
            >
              <div className="flex items-start justify-between mb-2">
                <span className="text-xl">{order.category.split(' ')[1]}</span>
                <PriorityBadge priority={order.priority} />
              </div>
              <p className="text-large font-medium">{order.description}</p>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                📍 {order.address} • {Math.round(order.distance)} м от вас
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                👤 {order.customer_name || 'Заказчик'}
              </p>
              <div className="mt-3">
                <button
                  onClick={() => acceptOrder(order.id)}
                  className="btn-large btn-primary w-full"
                >
                  🤝 Взять заказ
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      )}
      
      <button onClick={() => onNavigate('my_orders')} className="btn-large btn-outline w-full mt-6">
        📋 Все мои заказы
      </button>
    </div>
  );
}

function MyOrdersScreen({ onBack }: { onBack: () => void }) {
  const { user } = useContext(AuthContext);
  const [orders, setOrders] = useState<Order[]>([]);
  const [ratingOrder, setRatingOrder] = useState<Order | null>(null);
  const [score, setScore] = useState(5);
  const [comment, setComment] = useState('');

  useEffect(() => {
    const data = loadData();
    const myOrders = data.orders.filter(
      o => o.customer_id === user?.id || o.executor_id === user?.id
    );
    setOrders(myOrders.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()));
  }, [user]);

  const submitRating = () => {
    if (!ratingOrder) return;
    const data = loadData();
    const order = data.orders.find(o => o.id === ratingOrder.id);
    if (order) {
      order.rating = score;
      order.status = 'completed';
      // Обновляем рейтинг исполнителя
      if (order.executor_id) {
        const executor = data.users.find(u => u.id === order.executor_id);
        if (executor) {
          const executorOrders = data.orders.filter(o => o.executor_id === executor.id && o.rating);
          const avg = executorOrders.reduce((sum, o) => sum + (o.rating || 0), 0) / executorOrders.length;
          executor.rating = Math.round(avg * 10) / 10;
        }
      }
      saveData(data);
    }
    setRatingOrder(null);
    setScore(5);
    setComment('');
    // Обновить список
    const data2 = loadData();
    setOrders(data2.orders.filter(
      o => o.customer_id === user?.id || o.executor_id === user?.id
    ).sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()));
  };

  return (
    <div className="p-4 max-w-lg mx-auto animate-fade-in">
      <button onClick={onBack} className="text-large text-primary dark:text-blue-300 font-semibold mb-4 flex items-center gap-2">
        ← Назад
      </button>
      
      <h1 className="text-xlarge font-bold mb-6">Мои заказы</h1>
      
      {orders.length === 0 ? (
        <div className="card text-center py-8 text-gray-500 dark:text-gray-400">
          <div className="text-4xl mb-2">📋</div>
          <p className="text-large">Заказов пока нет</p>
        </div>
      ) : (
        <div className="space-y-3">
          {orders.map(order => (
            <div key={order.id} className="card">
              <div className="flex items-start justify-between mb-2">
                <span className="text-xl">{order.category.split(' ')[1]}</span>
                <StatusBadge status={order.status} />
              </div>
              <p className="text-large font-medium">{order.description}</p>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">📍 {order.address}</p>
              <div className="flex items-center justify-between mt-2">
                <PriorityBadge priority={order.priority} />
                <span className="text-xs text-gray-400">
                  {new Date(order.created_at).toLocaleDateString('ru-RU')}
                </span>
              </div>
              
              {/* Кнопка оценки для заказчика */}
              {order.status === 'accepted' && user?.role === 'customer' && (
                <button
                  onClick={() => setRatingOrder(order)}
                  className="btn-large btn-primary w-full mt-3"
                >
                  ⭐ Оценить работу
                </button>
              )}
              
              {/* Кнопка завершения для исполнителя */}
              {order.status === 'accepted' && user?.role === 'executor' && (
                <button
                  onClick={() => {
                    const d = loadData();
                    const o = d.orders.find(x => x.id === order.id);
                    if (o) { o.status = 'completed'; saveData(d); }
                    const data2 = loadData();
                    setOrders(data2.orders.filter(
                      o => o.customer_id === user?.id || o.executor_id === user?.id
                    ).sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()));
                  }}
                  className="btn-large btn-success w-full mt-3"
                >
                  ✅ Завершить
                </button>
              )}
              
              {order.rating && (
                <div className="mt-2 pt-2 border-t border-gray-100 dark:border-gray-700">
                  <StarRating score={order.rating} size="sm" />
                </div>
              )}
            </div>
          ))}
        </div>
      )}
      
      {/* Диалог оценки */}
      <AnimatePresence>
        {ratingOrder && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50"
          >
            <motion.div
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              className="card w-full max-w-sm"
            >
              <h3 className="text-xlarge font-bold mb-4">⭐ Оцените работу</h3>
              <p className="text-large mb-4">{ratingOrder.description}</p>
              
              <div className="flex justify-center mb-4">
                <StarRating score={score} onChange={setScore} size="lg" />
              </div>
              
              <textarea
                value={comment}
                onChange={e => setComment(e.target.value)}
                className="w-full p-3 border-2 border-gray-200 dark:border-gray-600 rounded-xl bg-white dark:bg-slate-700 dark:text-white text-lg mb-4 resize-none"
                placeholder="Комментарий (необязательно)"
                rows={2}
              />
              
              <div className="flex gap-3">
                <button onClick={() => setRatingOrder(null)} className="btn-large btn-outline flex-1">
                  Отмена
                </button>
                <button onClick={submitRating} className="btn-large btn-primary flex-1">
                  ✅ Оценить
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function ProfileScreen({ onLogout }: { onLogout: () => void }) {
  const { user } = useContext(AuthContext);
  const { dark, toggle } = useContext(ThemeContext);

  return (
    <div className="p-4 max-w-lg mx-auto animate-fade-in">
      <h1 className="text-xlarge font-bold mb-6">Профиль</h1>
      
      <div className="card mb-4">
        <div className="flex items-center gap-4 mb-4">
          <div className="w-16 h-16 rounded-full bg-primary flex items-center justify-center text-white text-2xl font-bold">
            {user?.first_name?.charAt(0)}
          </div>
          <div>
            <p className="text-large font-bold">{user?.first_name}</p>
            <p className="text-gray-500 dark:text-gray-400">{user?.phone}</p>
            <p className="text-sm text-gray-400">
              {user?.role === 'customer' ? '👴 Заказчик' : '🙋 Исполнитель'}
            </p>
          </div>
        </div>
        
        <div className="flex items-center gap-2">
          <span className="text-large">Рейтинг:</span>
          <StarRating score={Math.round(user?.rating || 5)} size="sm" />
          <span className="text-large font-bold">{user?.rating?.toFixed(1)}</span>
        </div>
      </div>
      
      <div className="space-y-3">
        <button
          onClick={toggle}
          className="card w-full flex items-center justify-between hover:border-primary transition-colors cursor-pointer"
        >
          <span className="text-large font-medium">
            {dark ? '☀️ Светлая тема' : '🌙 Тёмная тема'}
          </span>
          <div className={`w-14 h-8 rounded-full transition-colors ${dark ? 'bg-primary' : 'bg-gray-300'} relative`}>
            <div className={`w-6 h-6 rounded-full bg-white absolute top-1 transition-transform ${dark ? 'translate-x-7' : 'translate-x-1'}`} />
          </div>
        </button>
        
        <button
          onClick={() => {
            localStorage.removeItem('moe_delo_token');
            onLogout();
          }}
          className="card w-full flex items-center justify-between hover:border-danger transition-colors cursor-pointer"
        >
          <span className="text-large font-medium text-danger">🚪 Выйти из аккаунта</span>
          <span className="text-gray-400">→</span>
        </button>
      </div>
      
      {/* Информация о проекте */}
      <div className="card mt-6 bg-blue-50 dark:bg-blue-900/20">
        <h3 className="font-bold text-large mb-2">🤝 О проекте «Моё дело»</h3>
        <p className="text-gray-600 dark:text-gray-300">
          Платформа connects пожилых людей с волонтёрами и специалистами. 
          ИИ автоматически определяет категорию и срочность заказа.
        </p>
        <div className="mt-3 text-sm text-gray-500 dark:text-gray-400">
          <p>Версия: 1.0.0</p>
          <p>Технологии: React, Go, Flutter, PostgreSQL</p>
        </div>
      </div>
    </div>
  );
}

// ==================== НАВИГАЦИЯ ====================

function BottomNav({ active, onNavigate }: { active: string; onNavigate: (s: string) => void }) {
  const { user } = useContext(AuthContext);
  const isCustomer = user?.role === 'customer';
  
  const items = isCustomer
    ? [
        { id: 'customer', icon: '🏠', label: 'Главная' },
        { id: 'new_order', icon: '📝', label: 'Заказ' },
        { id: 'my_orders', icon: '📋', label: 'Мои' },
        { id: 'profile', icon: '👤', label: 'Профиль' },
      ]
    : [
        { id: 'executor', icon: '🏠', label: 'Заказы' },
        { id: 'my_orders', icon: '📋', label: 'Мои' },
        { id: 'profile', icon: '👤', label: 'Профиль' },
      ];

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white dark:bg-slate-800 border-t border-gray-200 dark:border-gray-700 safe-area-bottom">
      <div className="flex justify-around max-w-lg mx-auto">
        {items.map(item => (
          <button
            key={item.id}
            onClick={() => onNavigate(item.id)}
            className={`flex flex-col items-center py-3 px-4 min-w-[70px] transition-colors ${
              active === item.id
                ? 'text-primary dark:text-blue-300'
                : 'text-gray-400 dark:text-gray-500'
            }`}
          >
            <span className="text-2xl">{item.icon}</span>
            <span className="text-xs font-medium mt-1">{item.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

// ==================== ГЛАВНОЕ ПРИЛОЖЕНИЕ ====================

export default function App() {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [screen, setScreen] = useState('login');
  const [dark, setDark] = useState(false);

  // Загрузка токена из localStorage
  useEffect(() => {
    const savedToken = localStorage.getItem('moe_delo_token');
    const savedUserId = localStorage.getItem('moe_delo_user_id');
    if (savedToken && savedUserId) {
      const data = loadData();
      const foundUser = data.users.find(u => u.id === parseInt(savedUserId));
      if (foundUser) {
        setUser(foundUser);
        setToken(savedToken);
        setScreen(foundUser.role === 'customer' ? 'customer' : 'executor');
      }
    }
    // Загрузка темы
    const savedTheme = localStorage.getItem('moe_delo_theme');
    if (savedTheme === 'dark') setDark(true);
  }, []);

  // Применение тёмной темы
  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark);
    localStorage.setItem('moe_delo_theme', dark ? 'dark' : 'light');
  }, [dark]);

  const login = (phone: string, password: string): string | null => {
    const data = loadData();
    const found = data.users.find(u => u.phone === phone && u.password === password);
    if (!found) return 'Неверный телефон или пароль';
    
    const fakeToken = btoa(`${found.id}:${Date.now()}`);
    setUser(found);
    setToken(fakeToken);
    localStorage.setItem('moe_delo_token', fakeToken);
    localStorage.setItem('moe_delo_user_id', found.id.toString());
    setScreen(found.role === 'customer' ? 'customer' : 'executor');
    return null;
  };

  const register = (phone: string, password: string, role: string, firstName: string): string | null => {
    const data = loadData();
    if (data.users.find(u => u.phone === phone)) return 'Этот телефон уже зарегистрирован';
    
    const newUser = {
      id: data.nextUserId,
      phone,
      password,
      role: role as 'customer' | 'executor',
      first_name: firstName,
      rating: 5.0,
    };
    data.users.push(newUser);
    data.nextUserId++;
    saveData(data);
    
    const fakeToken = btoa(`${newUser.id}:${Date.now()}`);
    setUser(newUser);
    setToken(fakeToken);
    localStorage.setItem('moe_delo_token', fakeToken);
    localStorage.setItem('moe_delo_user_id', newUser.id.toString());
    setScreen(role === 'customer' ? 'customer' : 'executor');
    return null;
  };

  const logout = () => {
    setUser(null);
    setToken(null);
    localStorage.removeItem('moe_delo_token');
    localStorage.removeItem('moe_delo_user_id');
    setScreen('login');
  };

  const authContext: AuthContextType = { user, token, login, register, logout };
  const themeContext: ThemeContextType = { dark, toggle: () => setDark(!dark) };

  const renderScreen = () => {
    switch (screen) {
      case 'login':
        return <LoginScreen onLogin={() => {}} />;
      case 'customer':
        return <CustomerScreen onNavigate={setScreen} />;
      case 'new_order':
        return <NewOrderScreen onBack={() => setScreen('customer')} />;
      case 'executor':
        return <ExecutorScreen onNavigate={setScreen} />;
      case 'my_orders':
        return <MyOrdersScreen onBack={() => setScreen(user?.role === 'customer' ? 'customer' : 'executor')} />;
      case 'profile':
        return <ProfileScreen onLogout={logout} />;
      default:
        return <LoginScreen onLogin={() => {}} />;
    }
  };

  return (
    <AuthContext.Provider value={authContext}>
      <ThemeContext.Provider value={themeContext}>
        <div className={`min-h-screen bg-gray-50 dark:bg-slate-900 text-gray-900 dark:text-gray-100 transition-colors`}>
          {screen !== 'login' && (
            <header className="bg-primary dark:bg-slate-800 text-white p-4 sticky top-0 z-40 shadow-md">
              <div className="max-w-lg mx-auto flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="text-2xl">🤝</span>
                  <span className="font-bold text-lg">Моё дело</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm opacity-80">
                    {user?.role === 'customer' ? '👴 Заказчик' : '🙋 Исполнитель'}
                  </span>
                </div>
              </div>
            </header>
          )}
          
          <main className={screen !== 'login' ? 'pb-24' : ''}>
            <AnimatePresence mode="wait">
              <motion.div
                key={screen}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.2 }}
              >
                {renderScreen()}
              </motion.div>
            </AnimatePresence>
          </main>
          
          {screen !== 'login' && (
            <BottomNav active={screen} onNavigate={setScreen} />
          )}
        </div>
      </ThemeContext.Provider>
    </AuthContext.Provider>
  );
}
