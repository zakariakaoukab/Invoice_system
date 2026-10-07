/// All Arabic UI string constants.
/// Keep all user-facing Arabic text here for easy maintenance.
class AppStrings {
  AppStrings._();

  // App
  static const appName = 'دار بلعمري';
  static const appSubtitle = 'نظام نقطة البيع والفوترة';

  // Navigation / Sidebar
  static const navDashboard = 'لوحة التحكم';
  static const navPos = 'نقطة البيع';
  static const navOrderHistory = 'سجل الطلبات';
  static const navProducts = 'المنتجات';
  static const navUsers = 'إدارة المستخدمين';
  static const navLogout = 'تسجيل الخروج';

  // Auth
  static const login = 'تسجيل الدخول';
  static const email = 'البريد الإلكتروني';
  static const password = 'كلمة المرور';
  static const loginButton = 'دخول';
  static const loginError = 'فشل تسجيل الدخول. تحقق من بياناتك.';
  static const invalidEmail = 'البريد الإلكتروني غير صحيح';
  static const requiredField = 'هذا الحقل مطلوب';

  // Setup Wizard
  static const setupTitle = 'إعداد الحساب الأول';
  static const setupSubtitle = 'إنشاء حساب المسؤول الرئيسي';
  static const setupName = 'الاسم الكامل';
  static const setupEmail = 'البريد الإلكتروني';
  static const setupPassword = 'كلمة المرور';
  static const setupConfirmPassword = 'تأكيد كلمة المرور';
  static const setupButton = 'إنشاء الحساب';
  static const setupSuccess = 'تم إنشاء الحساب بنجاح!';
  static const setupPasswordMismatch = 'كلمتا المرور غير متطابقتين';
  static const setupPasswordTooShort = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  // Dashboard
  static const dashboardTitle = 'لوحة التحكم';
  static const monthlySales = 'مبيعات هذا الشهر';
  static const monthlyOrders = 'عدد الطلبات هذا الشهر';
  static const avgOrderValue = 'متوسط قيمة الطلب';
  static const salesChart = 'مخطط المبيعات الشهرية';
  static const topProducts = 'أكثر المنتجات مبيعاً';
  static const noData = 'لا توجد بيانات';

  // Products
  static const productsTitle = 'المنتجات';
  static const addProduct = 'إضافة منتج';
  static const editProduct = 'تعديل المنتج';
  static const deleteProduct = 'حذف المنتج';
  static const productName = 'اسم المنتج';
  static const productDescription = 'الوصف';
  static const productPrice = 'السعر (DH)';
  static const productStock = 'الكمية في المخزون';
  static const productImage = 'صورة المنتج';
  static const selectImage = 'اختر صورة';
  static const uploadingImage = 'جارٍ رفع الصورة...';
  static const deleteConfirm = 'هل أنت متأكد من حذف هذا المنتج؟';
  static const deleteConfirmButton = 'حذف';
  static const cancel = 'إلغاء';
  static const save = 'حفظ';
  static const edit = 'تعديل';
  static const delete = 'حذف';
  static const outOfStock = 'نفد المخزون';
  static const inStock = 'متوفر';
  static const stockUnits = 'وحدة';

  // POS
  static const posTitle = 'نقطة البيع - طلب جديد';
  static const searchProducts = 'ابحث عن منتج...';
  static const cart = 'سلة الطلب';
  static const emptyCart = 'السلة فارغة';
  static const customerName = 'اسم الزبون';
  static const customerDetails = 'تفاصيل الزبون (هاتف / عنوان)';
  static const quantity = 'الكمية';
  static const unitPrice = 'السعر الوحدة';
  static const subtotal = 'المجموع الجزئي';
  static const grandTotal = 'المجموع الكلي';
  static const submitOrder = 'إتمام الطلب';
  static const clearCart = 'مسح السلة';
  static const insufficientStock = 'الكمية المطلوبة غير متوفرة في المخزون';
  static const orderSuccess = 'تم تسجيل الطلب بنجاح!';
  static const orderError = 'حدث خطأ أثناء حفظ الطلب';
  static const customerNameRequired = 'يرجى إدخال اسم الزبون';
  static const cartEmptyError = 'السلة فارغة، أضف منتجات أولاً';

  // Order History
  static const ordersTitle = 'سجل الطلبات';
  static const invoiceNumber = 'رقم الفاتورة';
  static const dateTime = 'التاريخ والوقت';
  static const customerNameCol = 'اسم الزبون';
  static const createdBy = 'تم بواسطة';
  static const totalAmount = 'المجموع';
  static const actions = 'الإجراءات';
  static const viewDetails = 'التفاصيل';
  static const printInvoice = 'طباعة الفاتورة';
  static const filterByDate = 'تصفية بالتاريخ';
  static const filterByCashier = 'تصفية بالمُنشئ';
  static const searchOrders = 'بحث (رقم فاتورة / اسم زبون)';
  static const orderDetails = 'تفاصيل الطلب';
  static const clearFilter = 'مسح التصفية';
  static const allCashiers = 'كل الموظفين';

  // Users
  static const usersTitle = 'إدارة المستخدمين';
  static const addUser = 'إضافة مستخدم';
  static const userName = 'الاسم الكامل';
  static const userEmail = 'البريد الإلكتروني';
  static const userRole = 'الدور';
  static const userPassword = 'كلمة المرور';
  static const roleAdmin = 'مسؤول';
  static const roleStandard = 'موظف مبيعات';
  static const createdAt = 'تاريخ الإنشاء';
  static const userCreatedSuccess = 'تم إنشاء المستخدم بنجاح';
  static const userCreatedError = 'خطأ في إنشاء المستخدم';

  // Reports
  static const navReports = 'التقارير';
  static const reportsTitle = 'التقارير والإحصائيات';
  static const reportsSubtitle = 'تحليل المبيعات والأداء';
  static const totalRevenue = 'إجمالي الإيرادات';
  static const totalOrdersCount = 'إجمالي الطلبات'; // Avoid conflict with totalOrders
  static const averageOrder = 'متوسط الطلب';
  static const salesTrend = 'مؤشر المبيعات';
  static const salesByProduct = 'المبيعات حسب المنتج';
  static const customDateRange = 'فترة مخصصة';
  static const last7Days = 'آخر 7 أيام';
  static const last30Days = 'آخر 30 يوم';
  static const thisMonth = 'هذا الشهر';
  static const allTime = 'كل الوقت';

  // General
  static const loading = 'جارٍ التحميل...';
  static const error = 'حدث خطأ';
  static const retry = 'إعادة المحاولة';
  static const close = 'إغلاق';
  static const confirm = 'تأكيد';
  static const success = 'تم بنجاح';
  static const add = 'إضافة';
  static const search = 'بحث';
  static const from = 'من';
  static const to = 'إلى';
}
