import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/hive_storage.dart';

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super(HiveStorage.getLocale());

  void setLocale(String locale) {
    HiveStorage.saveLocale(locale);
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>(
  (_) => LocaleNotifier(),
);

class S {
  final String locale;
  const S(this.locale);

  String get(String key) => _d[locale]?[key] ?? _d['es']![key] ?? key;

  // Navigation
  String get navHome => get('nav_home');
  String get navFinance => get('nav_finance');
  String get navSavings => get('nav_savings');
  String get navHabits => get('nav_habits');
  String get navHealth => get('nav_health');
  String get navSkills => get('nav_skills');

  // Common
  String get save => get('save');
  String get cancel => get('cancel');
  String get retry => get('retry');
  String get required => get('required');
  String get delete => get('delete');
  String get edit => get('edit');
  String get add => get('add');
  String get done => get('done');
  String get income => get('income');
  String get expense => get('expense');
  String get total => get('total');
  String get goal => get('goal');
  String get notes => get('notes');
  String get description => get('description');
  String get name => get('name');
  String get amount => get('amount');
  String get date => get('date');
  String get today => get('today');
  String get thisWeek => get('this_week');
  String get active => get('active');
  String get completed => get('completed');
  String get noData => get('no_data');
  String get minutes => get('minutes');
  String get hours => get('hours');
  String get days => get('days');
  String get sessions => get('sessions');
  String get quality => get('quality');
  String get loading => get('loading');

  // Auth
  String get welcomeBack => get('welcome_back');
  String get welcomeSubtitle => get('welcome_subtitle');
  String get email => get('email');
  String get emailHint => get('email_hint');
  String get emailInvalid => get('email_invalid');
  String get password => get('password');
  String get passwordHint => get('password_hint');
  String get passwordMin => get('password_min');
  String get signIn => get('sign_in');
  String get noAccount => get('no_account');
  String get createOne => get('create_one');
  String get startJourney => get('start_journey');
  String get registerSubtitle => get('register_subtitle');
  String get yourName => get('your_name');
  String get createAccount => get('create_account');
  String get haveAccount => get('have_account');
  String get signInLink => get('sign_in_link');

  // Dashboard
  String get goodMorning => get('good_morning');
  String get goodAfternoon => get('good_afternoon');
  String get goodEvening => get('good_evening');
  String get dailyInsight => get('daily_insight');
  String get couldNotLoad => get('could_not_load');
  String get totalBalance => get('total_balance');
  String get saved => get('saved');
  String get savingsProgress => get('savings_progress');
  String get hydration => get('hydration');
  String get sleep => get('sleep');
  String get notLogged => get('not_logged');
  String get learning => get('learning');
  String get quickActions => get('quick_actions');
  String get habitsToday => get('habits_today');
  String get productive => get('productive');
  String get qaExpense => get('qa_expense');
  String get qaWater => get('qa_water');
  String get qaHabit => get('qa_habit');
  String get qaStudy => get('qa_study');
  String get qaSavings => get('qa_savings');
  String get qaSleep => get('qa_sleep');
  String get qaPlan => get('qa_plan');
  String get qaLearn => get('qa_learn');

  // Finance
  String get finances => get('finances');
  String get transactions => get('transactions');
  String get filter => get('filter');
  String get noTransactions => get('no_transactions');
  String get noTransactionsDesc => get('no_transactions_desc');
  String get addTransaction => get('add_transaction');
  String get saveTransaction => get('save_transaction');
  String get descriptionOptional => get('description_optional');
  String get mainAccount => get('main_account');

  // Savings
  String get savingsFunds => get('savings_funds');
  String get yourFunds => get('your_funds');
  String get noFunds => get('no_funds');
  String get noFundsDesc => get('no_funds_desc');
  String get createFirstFund => get('create_first_fund');
  String get totalSaved => get('total_saved');
  String get achieved => get('achieved');
  String get monthsLeft => get('months_left');
  String get perMonth => get('per_month');
  String get addContribution => get('add_contribution');
  String get newSavingsFund => get('new_savings_fund');
  String get newFundSubtitle => get('new_fund_subtitle');
  String get fundName => get('fund_name');
  String get targetAmount => get('target_amount');
  String get currentAmount => get('current_amount');
  String get monthlyContrib => get('monthly_contrib');
  String get createFund => get('create_fund');
  String get addTo => get('add_to');
  String get amountToAdd => get('amount_to_add');
  String get fundPurpose => get('fund_purpose');
  String get fundPurposeHint => get('fund_purpose_hint');
  // Preset fund names
  String get presetEmergency => get('preset_emergency');
  String get presetTravel => get('preset_travel');
  String get presetCar => get('preset_car');
  String get presetStudies => get('preset_studies');
  String get presetHealth => get('preset_health');
  String get presetWedding => get('preset_wedding');
  String get presetTech => get('preset_tech');

  // Habits
  String get habits => get('habits');
  String get positiveHabits => get('positive_habits');
  String get breakingHabits => get('breaking_habits');
  String get noHabits => get('no_habits');
  String get noHabitsDesc => get('no_habits_desc');
  String get addFirstHabit => get('add_first_habit');
  String get bestStreak => get('best_streak');
  String get newHabit => get('new_habit');
  String get positive => get('positive');
  String get breakBad => get('break_bad');
  String get habitName => get('habit_name');
  String get createHabit => get('create_habit');
  String get streak => get('streak');
  String get last7Days => get('last_7_days');
  String get habitTip => get('habit_tip');
  String get habitTipDesc => get('habit_tip_desc');
  String get habitRewardTip => get('habit_reward_tip');

  // Health
  String get healthWellness => get('health_wellness');
  String get hydrationTab => get('hydration_tab');
  String get sleepTab => get('sleep_tab');
  String get mealsTab => get('meals_tab');
  String get quickAdd => get('quick_add');
  String get logSleep => get('log_sleep');
  String get sleepHistory => get('sleep_history');
  String get noSleepLogs => get('no_sleep_logs');
  String get bedtime => get('bedtime');
  String get wakeUp => get('wake_up');
  String get sleepQuality => get('sleep_quality');
  String get saveSleepLog => get('save_sleep_log');
  String get logMeal => get('log_meal');
  String get todayMeals => get('today_meals');
  String get noMealsToday => get('no_meals_today');
  String get whatDidYouEat => get('what_did_you_eat');
  String get caloriesOptional => get('calories_optional');
  String get breakfast => get('breakfast');
  String get lunch => get('lunch');
  String get dinner => get('dinner');
  String get snack => get('snack');

  // Planning
  String get weeklyPlan => get('weekly_plan');
  String get addPlanItem => get('add_plan_item');
  String get whatWillYouDo => get('what_will_you_do');
  String get addItem => get('add_item');
  String get nothingPlanned => get('nothing_planned');
  String get percentDone => get('percent_done');

  // Time Tracking
  String get timeTracking => get('time_tracking');
  String get todayActivity => get('today_activity');
  String get noTimeTracked => get('no_time_tracked');
  String get logTime => get('log_time');
  String get activityName => get('activity_name');
  String get duration => get('duration');
  String get saveEntry => get('save_entry');
  String get productivity => get('productivity');
  String get hTracked => get('h_tracked');
  String get wasted => get('wasted');
  String get study => get('study');

  // Learning
  String get yourLibrary => get('your_library');
  String get addToLibrary => get('add_to_library');
  String get title => get('title');
  String get authorCreator => get('author_creator');
  String get logStudySession => get('log_study_session');
  String get logSession => get('log_session');
  String get totalHours => get('total_hours');
  String get hThisWeek => get('h_this_week');
  String get inProgress => get('in_progress');
  String get emptyLibrary => get('empty_library');
  String get emptyLibraryDesc => get('empty_library_desc');
  String get addFirstItem => get('add_first_item');

  // Rewards
  String get rewards => get('rewards');
  String get rewardSystem => get('reward_system');
  String get rewardSystemDesc => get('reward_system_desc');
  String get readyToClaim => get('ready_to_claim');
  String get upcomingRewards => get('upcoming_rewards');
  String get claimedRewards => get('claimed_rewards');
  String get noRewards => get('no_rewards');
  String get noRewardsDesc => get('no_rewards_desc');
  String get createFirstReward => get('create_first_reward');
  String get createReward => get('create_reward');
  String get createRewardDesc => get('create_reward_desc');
  String get rewardName => get('reward_name');
  String get claim => get('claim');
  String get unlock => get('unlock');

  // Analytics
  String get analytics => get('analytics');
  String get incomeVsExpenses => get('income_vs_expenses');
  String get last6Months => get('last_6_months');
  String get noFinancialData => get('no_financial_data');
  String get monthlyNet => get('monthly_net');
  String get habitConsistency => get('habit_consistency');
  String get last90Days => get('last_90_days');
  String get less => get('less');
  String get more => get('more');
  String get noYearlyData => get('no_yearly_data');
  String get productiveHoursMonth => get('productive_hours_month');
  String get overview => get('overview');
  String get financeTab => get('finance_tab');

  // Settings
  String get settingsTitle => get('settings_title');
  String get language => get('language');
  String get spanish => get('spanish');
  String get english => get('english');
  String get appearance => get('appearance');
  String get darkMode => get('dark_mode');
  String get security => get('security');
  String get pinProtection => get('pin_protection');
  String get pinDesc => get('pin_desc');
  String get biometric => get('biometric');
  String get biometricDesc => get('biometric_desc');
  String get goals => get('goals');
  String get dailyWaterGoal => get('daily_water_goal');
  String get sleepGoal => get('sleep_goal');
  String get about => get('about');
  String get appVersion => get('app_version');
  String get signOut => get('sign_out');
  String get logout => get('logout');

  // Finance extended
  String get deleteTransaction => get('delete_transaction');
  String get confirmDelete => get('confirm_delete');
  String get cannotUndo => get('cannot_undo');
  String get addCategory => get('add_category');
  String get categoryName => get('category_name');
  String get expenseCategories => get('expense_categories');
  String get incomeCategories => get('income_categories');
  String get allTime => get('all_time');
  String get thisMonth => get('this_month');
  String get byCategory => get('by_category');
  String get gymDays => get('gym_days');
  String get healthScore => get('health_score');
  String get logGym => get('log_gym');
  String get gymHistory => get('gym_history');
  String get healthTips => get('health_tips');
  String get gymTab => get('gym_tab');
  String get noGymSessions => get('no_gym_sessions');
  String get daysThisMonth => get('days_this_month');
  String get durationMin => get('duration_min');
  String get gymTip => get('gym_tip');
  String get sleepTip => get('sleep_tip');
  String get waterTip => get('water_tip');

  // Nutrition
  String get nutritionTab => get('nutrition_tab');
  String get myBody => get('my_body');
  String get weightKg => get('weight_kg');
  String get heightCm => get('height_cm');
  String get bmi => get('bmi');
  String get waterGoal => get('water_goal');
  String get saveMetrics => get('save_metrics');
  String get dailyFoodLog => get('daily_food_log');
  String get logFood => get('log_food');
  String get servings => get('servings');
  String get mealTime => get('meal_time');
  String get todayBalance => get('today_balance');
  String get nutritionScore => get('nutrition_score');
  String get excellent => get('excellent');
  String get good => get('good');
  String get needsWork => get('needs_work');
  String get failingTitle => get('failing_title');
  String get missingTitle => get('missing_title');
  String get weeklyTreats => get('weekly_treats');
  String get noFoodLogged => get('no_food_logged');
  String get carbsLabel => get('carbs_label');
  String get proteinLabel => get('protein_label');
  String get legumeLabel => get('legume_label');
  String get veggiesLabel => get('veggies_label');
  String get fruitsLabel => get('fruits_label');
  String get dairyLabel => get('dairy_label');
  String get treatsLabel => get('treats_label');
  String get portions => get('portions');
  String get glasses => get('glasses');
  String get units => get('units');
  String get cups => get('cups');
  String get deleteFood => get('delete_food');
  String get bodyNormal => get('body_normal');
  String get bodyOverweight => get('body_overweight');
  String get bodyObese => get('body_obese');
  String get bodyUnder => get('body_under');

  // Hydration schedule
  String get hydrSchedule => get('hydr_schedule');
  String get smallGlass => get('small_glass');
  String get bigGlass => get('big_glass');
  String get bottle => get('bottle');
  String get thermos => get('thermos');
  String get recommendedTimes => get('recommended_times');

  // Skills
  String get skillsTitle => get('skills_title');
  String get addSkill => get('add_skill');
  String get loggedToday => get('logged_today');
  String get allCategories => get('all_categories');
  String get reference => get('reference');
  String get skillName => get('skill_name');
  String get skillDesc => get('skill_desc');
  String get targetDays => get('target_days');
  String get category => get('category');
  String get noSkills => get('no_skills');
  String get totalSessions => get('total_sessions');
  String get totalMinutes => get('total_minutes');
  String get progress => get('progress');
  String get catLanguage => get('cat_language');
  String get catFitness => get('cat_fitness');
  String get catSpiritual => get('cat_spiritual');
  String get catTech => get('cat_tech');
  String get catCommunication => get('cat_communication');
  String get catReading => get('cat_reading');
  String get catOther => get('cat_other');

  // Diary
  String get diaryTitle => get('diary_title');
  String get diaryToday => get('diary_today');
  String get diaryHistory => get('diary_history');
  String get diaryAdd => get('diary_add');
  String get diaryAddTitle => get('diary_add_title');
  String get diaryHint => get('diary_hint');
  String get diaryPresets => get('diary_presets');
  String get diaryEmpty => get('diary_empty');
  String get diaryEmptyToday => get('diary_empty_today');
  String get diaryEmptyTodayDesc => get('diary_empty_today_desc');
  String get yesterday => get('yesterday');

  // Weekly review
  String get weeklyReviewTitle => get('weekly_review_title');
  String get weeklyReviewScore => get('weekly_review_score');
  String get weeklyReviewHabits => get('weekly_review_habits');
  String get weeklyReviewGym => get('weekly_review_gym');
  String get weeklyReviewSleep => get('weekly_review_sleep');
  String get weeklyReviewProductivity => get('weekly_review_productivity');
  String get weeklyReviewDiary => get('weekly_review_diary');

  // Day review
  String get dayReviewTitle => get('day_review_title');
  String get dayScore => get('day_score');
  String get dayActivities => get('day_activities');

  // Budget
  String get budgetTitle => get('budget_title');
  String get budgetOf => get('budget_of');
  String get setBudget => get('set_budget');
  String get budgetAlert => get('budget_alert');
  String get noBudget => get('no_budget');

  // Activity types
  String get actWork => get('act_work');
  String get actStudy => get('act_study');
  String get actExercise => get('act_exercise');
  String get actLearning => get('act_learning');
  String get actRest => get('act_rest');
  String get actSocial => get('act_social');
  String get actRoutine => get('act_routine');
  String get actPhone => get('act_phone');
  String get actEntertainment => get('act_entertainment');
  String get actReading => get('act_reading');

  // Time categories
  String get catStudy => get('cat_study');
  String get catProductive => get('cat_productive');
  String get catLearning => get('cat_learning');
  String get catPhone => get('cat_phone');
  String get catEntertainment => get('cat_entertainment');
  String get catWasted => get('cat_wasted');
  String get catExercise => get('cat_exercise');

  static const Map<String, Map<String, String>> _d = {
    'es': {
      // Navigation
      'nav_home': 'Inicio', 'nav_finance': 'Finanzas', 'nav_savings': 'Ahorros',
      'nav_habits': 'Hábitos', 'nav_health': 'Salud', 'nav_skills': 'Habilidades',
      // Common
      'save': 'Guardar', 'cancel': 'Cancelar', 'retry': 'Reintentar', 'required': 'Requerido',
      'delete': 'Eliminar', 'edit': 'Editar', 'add': 'Agregar', 'done': 'Listo',
      'income': 'Ingresos', 'expense': 'Gasto', 'total': 'Total', 'goal': 'Meta',
      'notes': 'Notas', 'description': 'Descripción', 'name': 'Nombre',
      'amount': 'Monto', 'date': 'Fecha', 'today': 'Hoy', 'this_week': 'Esta semana',
      'active': 'Activo', 'completed': 'Completado', 'no_data': 'Sin datos',
      'minutes': 'min', 'hours': 'h', 'days': 'días', 'sessions': 'sesiones',
      'quality': 'Calidad', 'loading': 'Cargando...',
      // Auth
      'welcome_back': 'Bienvenido de nuevo', 'welcome_subtitle': 'Continúa construyendo tu mejor vida.',
      'email': 'Correo electrónico', 'email_hint': 'Ingresa tu correo', 'email_invalid': 'Correo inválido',
      'password': 'Contraseña', 'password_hint': 'Ingresa tu contraseña', 'password_min': 'Mínimo 8 caracteres',
      'sign_in': 'Iniciar sesión', 'no_account': '¿No tienes cuenta?', 'create_one': 'Crear una',
      'start_journey': 'Comienza tu camino', 'register_subtitle': 'Segunda Vida — tu compañero de vida personal.',
      'your_name': 'Tu nombre (opcional)', 'create_account': 'Crear cuenta',
      'have_account': '¿Ya tienes cuenta?', 'sign_in_link': 'Inicia sesión',
      // Dashboard
      'good_morning': 'Buenos días', 'good_afternoon': 'Buenas tardes', 'good_evening': 'Buenas noches',
      'daily_insight': 'Tu insight del día', 'could_not_load': 'No se pudo cargar el dashboard',
      'total_balance': 'Balance Total', 'saved': 'Ahorrado', 'savings_progress': 'Progreso de Ahorro',
      'hydration': 'Hidratación', 'sleep': 'Sueño', 'not_logged': 'Sin registrar',
      'learning': 'Aprendizaje', 'quick_actions': 'Acciones Rápidas',
      'habits_today': 'Hábitos hoy', 'productive': 'Productivo',
      'qa_expense': 'Gasto', 'qa_water': 'Agua', 'qa_habit': 'Hábito', 'qa_study': 'Estudio',
      'qa_savings': 'Ahorro', 'qa_sleep': 'Sueño', 'qa_plan': 'Plan', 'qa_learn': 'Aprender',
      // Finance
      'finances': 'Finanzas', 'transactions': 'Transacciones', 'filter': 'Filtrar',
      'no_transactions': 'Sin transacciones aún',
      'no_transactions_desc': 'Registra tus ingresos y gastos para entender tus finanzas.',
      'add_transaction': 'Agregar transacción', 'save_transaction': 'Guardar transacción',
      'description_optional': 'Descripción (opcional)', 'main_account': 'Cuenta Principal',
      // Savings
      'savings_funds': 'Fondos de Ahorro', 'your_funds': 'Tus Fondos',
      'no_funds': 'Sin fondos de ahorro aún',
      'no_funds_desc': 'Crea tu primera meta de ahorro y empieza tu camino.',
      'create_first_fund': 'Crear Primer Fondo', 'total_saved': 'Total Ahorrado',
      'achieved': 'Logrado', 'months_left': 'meses restantes', 'per_month': '/mes',
      'add_contribution': 'Agregar Contribución', 'new_savings_fund': 'Nuevo Fondo de Ahorro',
      'new_fund_subtitle': 'Define una meta y sigue tu progreso', 'fund_name': 'Nombre del fondo',
      'target_amount': 'Monto objetivo', 'current_amount': 'Monto actual',
      'monthly_contrib': 'Contribución mensual', 'create_fund': 'Crear Fondo',
      'add_to': 'Agregar a', 'amount_to_add': 'Monto a agregar',
      'fund_purpose': '¿Para qué es este ahorro?',
      'fund_purpose_hint': 'Ej: Viaje a Colombia, Computadora nueva...',
      'preset_emergency': 'Emergencias', 'preset_travel': 'Viaje', 'preset_car': 'Auto',
      'preset_studies': 'Estudios', 'preset_health': 'Salud', 'preset_wedding': 'Boda',
      'preset_tech': 'Tecnología',
      // Habits
      'habits': 'Hábitos', 'positive_habits': 'Hábitos Positivos', 'breaking_habits': 'Malos Hábitos a Eliminar',
      'no_habits': 'Sin hábitos registrados', 'no_habits_desc': 'Pequeñas acciones constantes construyen vidas extraordinarias.',
      'add_first_habit': 'Agregar Primer Hábito', 'best_streak': 'Mejor racha',
      'new_habit': 'Nuevo Hábito', 'positive': '✅ Positivo', 'break_bad': '🚫 Eliminar',
      'habit_name': 'Nombre del hábito', 'create_habit': 'Crear Hábito',
      'streak': 'racha', 'last_7_days': 'últimos 7 días',
      'habit_tip': 'Empieza con un solo hábito',
      'habit_tip_desc': 'La ciencia dice que es mejor dominar un hábito antes de agregar más. Elige uno significativo y sé constante 30 días.',
      'habit_reward_tip': 'Completa 30 días seguidos y gana una insignia de logro 🏆. ¡La constancia es tu superpoder!',
      // Health
      'health_wellness': 'Salud y Bienestar', 'hydration_tab': 'Hidratación',
      'sleep_tab': 'Sueño', 'meals_tab': 'Comidas', 'quick_add': 'Agregar rápido',
      'log_sleep': 'Registrar Sueño', 'sleep_history': 'Historial de Sueño',
      'no_sleep_logs': 'Sin registros de sueño. Empieza esta noche.',
      'bedtime': 'Hora de dormir', 'wake_up': 'Hora de despertar',
      'sleep_quality': 'Calidad del sueño', 'save_sleep_log': 'Guardar Registro',
      'log_meal': 'Registrar Comida', 'today_meals': 'Comidas de Hoy',
      'no_meals_today': 'Sin comidas registradas hoy.',
      'what_did_you_eat': '¿Qué comiste?', 'calories_optional': 'Calorías (opcional)',
      'breakfast': 'Desayuno', 'lunch': 'Almuerzo', 'dinner': 'Cena', 'snack': 'Merienda',
      // Planning
      'weekly_plan': 'Plan Semanal', 'add_plan_item': 'Agregar Actividad',
      'what_will_you_do': '¿Qué harás?', 'add_item': 'Agregar', 'nothing_planned': 'Nada planeado',
      'percent_done': '% completado',
      // Time Tracking
      'time_tracking': 'Control de Tiempo', 'today_activity': 'Actividad de Hoy',
      'no_time_tracked': 'Sin tiempo registrado hoy', 'log_time': 'Registrar Tiempo',
      'activity_name': 'Nombre de actividad (opcional)', 'duration': 'Duración (minutos)',
      'save_entry': 'Guardar', 'productivity': 'Productividad', 'h_tracked': 'h registradas',
      'wasted': 'Perdido', 'study': 'Estudio',
      // Learning
      'your_library': 'Tu Biblioteca', 'add_to_library': 'Agregar a Biblioteca',
      'title': 'Título', 'author_creator': 'Autor / Creador (opcional)',
      'log_study_session': 'Registrar Sesión de Estudio', 'log_session': 'Registrar Sesión',
      'total_hours': 'Total de Horas', 'h_this_week': 'h esta semana',
      'in_progress': 'En Progreso', 'empty_library': 'Tu biblioteca está vacía',
      'empty_library_desc': 'Agrega libros, cursos y temas para seguir tu aprendizaje.',
      'add_first_item': 'Agregar Primer Elemento',
      // Rewards
      'rewards': 'Recompensas', 'reward_system': 'Sistema de Recompensas',
      'reward_system_desc': 'Logra metas, gana recompensas.', 'ready_to_claim': '🎉 Listo para Reclamar',
      'upcoming_rewards': 'Próximas Recompensas', 'claimed_rewards': 'Recompensas Reclamadas',
      'no_rewards': 'Sin recompensas aún',
      'no_rewards_desc': 'Crea recompensas que se desbloqueen al lograr tus metas.',
      'create_first_reward': 'Crear Primera Recompensa', 'create_reward': 'Crear Recompensa',
      'create_reward_desc': '¿Qué ganarás por tus logros?',
      'reward_name': 'Nombre de la recompensa', 'claim': 'Reclamar', 'unlock': 'Desbloquear',
      // Analytics
      'analytics': 'Analíticas', 'income_vs_expenses': 'Ingresos vs Gastos',
      'last_6_months': 'Últimos 6 meses', 'no_financial_data': 'Sin datos financieros. Empieza a registrar transacciones.',
      'monthly_net': 'Neto Mensual', 'habit_consistency': 'Consistencia de Hábitos',
      'last_90_days': 'Últimos 90 días', 'less': 'Menos', 'more': 'Más',
      'no_yearly_data': 'Usa la app para ver tu resumen anual.',
      'productive_hours_month': 'Horas Productivas por Mes',
      'overview': 'Resumen', 'finance_tab': 'Finanzas',
      // Settings
      'settings_title': 'Configuración', 'language': 'Idioma', 'spanish': 'Español', 'english': 'English',
      'appearance': 'Apariencia', 'dark_mode': 'Modo Oscuro', 'security': 'Seguridad',
      'pin_protection': 'Protección PIN', 'pin_desc': 'Protege la app con un PIN de 4 dígitos',
      'biometric': 'Autenticación Biométrica', 'biometric_desc': 'Usa huella digital o Face ID',
      'goals': 'Metas', 'daily_water_goal': 'Meta diaria de agua',
      'sleep_goal': 'Meta de sueño', 'about': 'Acerca de',
      'app_version': 'Versión 1.0.0 — Sistema Operativo Personal',
      'sign_out': 'Cerrar sesión', 'logout': 'Cerrar sesión',
      // Finance extended
      'delete_transaction': 'Eliminar transacción', 'confirm_delete': '¿Eliminar?',
      'cannot_undo': 'Esta acción no se puede deshacer.',
      'add_category': 'Nueva categoría', 'category_name': 'Nombre de categoría',
      'expense_categories': 'Categorías de gasto', 'income_categories': 'Categorías de ingreso',
      'all_time': 'Todo', 'this_month': 'Este mes', 'by_category': 'Por categoría',
      'gym_days': 'Días de gym', 'health_score': 'Puntaje de salud',
      'log_gym': 'Registrar gym', 'gym_history': 'Historial de gym', 'health_tips': 'Consejos de salud',
      'gym_tab': 'Gym & Salud', 'no_gym_sessions': 'Sin sesiones de gym este mes',
      'days_this_month': 'días este mes', 'duration_min': 'min',
      'gym_tip': 'Intenta llegar al gym al menos 3 veces esta semana.',
      'sleep_tip': 'Duerme entre 7 y 9 horas para una recuperación óptima.',
      'water_tip': 'Toma un vaso de agua al despertar, antes de cada comida y antes de dormir.',
      // Nutrition
      'nutrition_tab': 'Nutrición', 'my_body': 'Mi Cuerpo', 'weight_kg': 'Peso (kg)',
      'height_cm': 'Talla (cm)', 'bmi': 'IMC', 'water_goal': 'Meta de agua',
      'save_metrics': 'Guardar medidas', 'daily_food_log': 'Registro del día',
      'log_food': 'Registrar alimento', 'servings': 'Porciones', 'meal_time': 'Tiempo de comida',
      'today_balance': 'Balance de hoy', 'nutrition_score': 'Puntaje nutricional',
      'excellent': 'Excelente', 'good': 'Bien', 'needs_work': 'Mejorar',
      'failing_title': 'En exceso hoy', 'missing_title': 'Sin consumir hoy', 'weekly_treats': 'Control semanal',
      'no_food_logged': 'Sin alimentos registrados hoy.\n¡Empieza registrando lo que comiste!',
      'carbs_label': 'Carbohidratos', 'protein_label': 'Proteínas', 'legume_label': 'Legumbres',
      'veggies_label': 'Verduras', 'fruits_label': 'Frutas', 'dairy_label': 'Lácteos', 'treats_label': 'Antojos',
      'portions': 'porciones', 'glasses': 'vasos', 'units': 'unidades', 'cups': 'tazas',
      'delete_food': 'Eliminar alimento',
      'body_normal': 'Normal', 'body_overweight': 'Sobrepeso', 'body_obese': 'Obesidad', 'body_under': 'Bajo peso',
      // Hydration schedule
      'hydr_schedule': 'Horario recomendado', 'small_glass': 'Vaso pequeño', 'big_glass': 'Vaso grande',
      'bottle': 'Botella', 'thermos': 'Termo', 'recommended_times': 'Horarios sugeridos',
      // Skills
      'skills_title': 'Habilidades', 'add_skill': 'Agregar habilidad',
      'logged_today': '✓ Registrado hoy', 'all_categories': 'Todas',
      'reference': 'Referencia', 'skill_name': 'Nombre de la habilidad',
      'skill_desc': 'Descripción (opcional)', 'target_days': 'Meta en días (ej. 30, 60, 90)',
      'category': 'Categoría', 'no_skills': 'Sin habilidades aún.\n¡Agrega una para empezar!',
      'total_sessions': 'Sesiones totales', 'total_minutes': 'Minutos totales', 'progress': 'Progreso',
      'cat_language': 'Idioma', 'cat_fitness': 'Ejercicio', 'cat_spiritual': 'Espiritual',
      'cat_tech': 'Tecnología', 'cat_communication': 'Comunicación', 'cat_reading': 'Lectura',
      'cat_other': 'Otro',
      // Diary
      'diary_title': 'Diario del Día', 'diary_today': 'Hoy', 'diary_history': 'Historial',
      'diary_add': 'Agregar', 'diary_add_title': '¿Qué hiciste hoy?',
      'diary_hint': 'Escribe lo que hiciste...', 'diary_presets': 'Atajos rápidos',
      'diary_empty': 'Sin entradas aún. Empieza registrando tu día.',
      'diary_empty_today': 'Registra tu primer momento del día',
      'diary_empty_today_desc': 'Toca aquí para agregar qué hiciste, viste o viviste hoy.',
      'yesterday': 'Ayer',
      // Weekly review
      'weekly_review_title': 'Resumen de la semana', 'weekly_review_score': 'Puntaje semanal',
      'weekly_review_habits': 'Hábitos', 'weekly_review_gym': 'Sesiones gym',
      'weekly_review_sleep': 'Sueño promedio', 'weekly_review_productivity': 'Horas productivas',
      'weekly_review_diary': 'Momentos registrados',
      // Day review
      'day_review_title': '¿Cómo fue tu día?', 'day_score': 'Puntaje del día',
      'day_activities': 'momentos hoy',
      // Budget
      'budget_title': 'Presupuesto', 'budget_of': 'de', 'set_budget': 'Establecer presupuesto',
      'budget_alert': 'Cerca del límite', 'no_budget': 'Sin presupuesto',
      // Activity & time types
      'act_work': 'Trabajo', 'act_study': 'Estudio', 'act_exercise': 'Ejercicio',
      'act_learning': 'Aprendizaje', 'act_rest': 'Descanso', 'act_social': 'Social',
      'act_routine': 'Rutina', 'act_phone': 'Teléfono', 'act_entertainment': 'Entretenimiento',
      'act_reading': 'Lectura',
      'cat_study': 'Estudio', 'cat_productive': 'Productivo', 'cat_learning': 'Aprendizaje',
      'cat_phone': 'Teléfono', 'cat_entertainment': 'Entretenimiento', 'cat_wasted': 'Perdido',
      'cat_exercise': 'Ejercicio',
    },
    'en': {
      // Navigation
      'nav_home': 'Home', 'nav_finance': 'Finance', 'nav_savings': 'Savings',
      'nav_habits': 'Habits', 'nav_health': 'Health', 'nav_skills': 'Skills',
      // Common
      'save': 'Save', 'cancel': 'Cancel', 'retry': 'Retry', 'required': 'Required',
      'delete': 'Delete', 'edit': 'Edit', 'add': 'Add', 'done': 'Done',
      'income': 'Income', 'expense': 'Expense', 'total': 'Total', 'goal': 'Goal',
      'notes': 'Notes', 'description': 'Description', 'name': 'Name',
      'amount': 'Amount', 'date': 'Date', 'today': 'Today', 'this_week': 'This week',
      'active': 'Active', 'completed': 'Completed', 'no_data': 'No data',
      'minutes': 'min', 'hours': 'h', 'days': 'days', 'sessions': 'sessions',
      'quality': 'Quality', 'loading': 'Loading...',
      // Auth
      'welcome_back': 'Welcome back', 'welcome_subtitle': 'Continue building your best life.',
      'email': 'Email', 'email_hint': 'Enter your email', 'email_invalid': 'Invalid email',
      'password': 'Password', 'password_hint': 'Enter your password', 'password_min': 'Minimum 8 characters',
      'sign_in': 'Sign In', 'no_account': "Don't have an account?", 'create_one': 'Create one',
      'start_journey': 'Start your journey', 'register_subtitle': 'Segunda Vida — your personal life companion.',
      'your_name': 'Your name (optional)', 'create_account': 'Create Account',
      'have_account': 'Already have an account?', 'sign_in_link': 'Sign in',
      // Dashboard
      'good_morning': 'Good morning', 'good_afternoon': 'Good afternoon', 'good_evening': 'Good evening',
      'daily_insight': 'Your daily insight', 'could_not_load': 'Could not load dashboard',
      'total_balance': 'Total Balance', 'saved': 'Saved', 'savings_progress': 'Savings Progress',
      'hydration': 'Hydration', 'sleep': 'Sleep', 'not_logged': 'Not logged',
      'learning': 'Learning', 'quick_actions': 'Quick Actions',
      'habits_today': 'Habits today', 'productive': 'Productive',
      'qa_expense': 'Expense', 'qa_water': 'Water', 'qa_habit': 'Habit', 'qa_study': 'Study',
      'qa_savings': 'Savings', 'qa_sleep': 'Sleep', 'qa_plan': 'Plan', 'qa_learn': 'Learn',
      // Finance
      'finances': 'Finances', 'transactions': 'Transactions', 'filter': 'Filter',
      'no_transactions': 'No transactions yet',
      'no_transactions_desc': 'Track your income and expenses to understand your finances.',
      'add_transaction': 'Add Transaction', 'save_transaction': 'Save Transaction',
      'description_optional': 'Description (optional)', 'main_account': 'Main Account',
      // Savings
      'savings_funds': 'Savings Funds', 'your_funds': 'Your Funds',
      'no_funds': 'No savings funds yet',
      'no_funds_desc': 'Create your first savings goal and start your journey.',
      'create_first_fund': 'Create First Fund', 'total_saved': 'Total Saved',
      'achieved': 'Achieved', 'months_left': 'months left', 'per_month': '/month',
      'add_contribution': 'Add Contribution', 'new_savings_fund': 'New Savings Fund',
      'new_fund_subtitle': 'Set a goal and track your progress', 'fund_name': 'Fund name',
      'target_amount': 'Target amount', 'current_amount': 'Current amount',
      'monthly_contrib': 'Monthly contrib.', 'create_fund': 'Create Fund',
      'add_to': 'Add to', 'amount_to_add': 'Amount to add',
      'fund_purpose': 'What is this savings for?',
      'fund_purpose_hint': 'e.g.: Trip to Colombia, New computer...',
      'preset_emergency': 'Emergency', 'preset_travel': 'Travel', 'preset_car': 'Car',
      'preset_studies': 'Studies', 'preset_health': 'Health', 'preset_wedding': 'Wedding',
      'preset_tech': 'Technology',
      // Habits
      'habits': 'Habits', 'positive_habits': 'Positive Habits', 'breaking_habits': 'Breaking Bad Habits',
      'no_habits': 'No habits tracked yet', 'no_habits_desc': 'Small consistent actions build extraordinary lives.',
      'add_first_habit': 'Add First Habit', 'best_streak': 'Best Streak',
      'new_habit': 'New Habit', 'positive': '✅ Positive', 'break_bad': '🚫 Break',
      'habit_name': 'Habit name', 'create_habit': 'Create Habit',
      'streak': 'streak', 'last_7_days': 'last 7 days',
      'habit_tip': 'Start with just one habit',
      'habit_tip_desc': 'Science says it\'s better to master one habit before adding more. Pick a meaningful one and be consistent for 30 days.',
      'habit_reward_tip': 'Complete 30 days in a row and earn an achievement badge 🏆. Consistency is your superpower!',
      // Health
      'health_wellness': 'Health & Wellness', 'hydration_tab': 'Hydration',
      'sleep_tab': 'Sleep', 'meals_tab': 'Meals', 'quick_add': 'Quick Add',
      'log_sleep': 'Log Sleep', 'sleep_history': 'Sleep History',
      'no_sleep_logs': 'No sleep logs yet. Start tracking tonight.',
      'bedtime': 'Bedtime', 'wake_up': 'Wake up',
      'sleep_quality': 'Sleep Quality', 'save_sleep_log': 'Save Sleep Log',
      'log_meal': 'Log Meal', 'today_meals': "Today's Meals",
      'no_meals_today': 'No meals logged today.',
      'what_did_you_eat': 'What did you eat?', 'calories_optional': 'Calories (optional)',
      'breakfast': 'Breakfast', 'lunch': 'Lunch', 'dinner': 'Dinner', 'snack': 'Snack',
      // Planning
      'weekly_plan': 'Weekly Plan', 'add_plan_item': 'Add Plan Item',
      'what_will_you_do': 'What will you do?', 'add_item': 'Add Item', 'nothing_planned': 'Nothing planned',
      'percent_done': '% done',
      // Time Tracking
      'time_tracking': 'Time Tracking', 'today_activity': "Today's Activity",
      'no_time_tracked': 'No time tracked today', 'log_time': 'Log Time',
      'activity_name': 'Activity name (optional)', 'duration': 'Duration (minutes)',
      'save_entry': 'Save Entry', 'productivity': 'Productivity', 'h_tracked': 'h tracked',
      'wasted': 'Wasted', 'study': 'Study',
      // Learning
      'your_library': 'Your Library', 'add_to_library': 'Add to Library',
      'title': 'Title', 'author_creator': 'Author / Creator (optional)',
      'log_study_session': 'Log Study Session', 'log_session': 'Log Session',
      'total_hours': 'Total Hours', 'h_this_week': 'h this week',
      'in_progress': 'In Progress', 'empty_library': 'Your library is empty',
      'empty_library_desc': 'Add books, courses and topics to track your learning journey.',
      'add_first_item': 'Add First Item',
      // Rewards
      'rewards': 'Rewards', 'reward_system': 'Reward System',
      'reward_system_desc': 'Achieve goals, earn rewards.', 'ready_to_claim': '🎉 Ready to Claim',
      'upcoming_rewards': 'Upcoming Rewards', 'claimed_rewards': 'Claimed Rewards',
      'no_rewards': 'No rewards yet',
      'no_rewards_desc': 'Create rewards that unlock when you achieve your goals.',
      'create_first_reward': 'Create First Reward', 'create_reward': 'Create Reward',
      'create_reward_desc': 'What will you earn for your achievements?',
      'reward_name': 'Reward name', 'claim': 'Claim', 'unlock': 'Unlock',
      // Analytics
      'analytics': 'Analytics', 'income_vs_expenses': 'Income vs Expenses',
      'last_6_months': 'Last 6 months', 'no_financial_data': 'No financial data yet. Start tracking transactions.',
      'monthly_net': 'Monthly Net', 'habit_consistency': 'Habit Consistency',
      'last_90_days': 'Last 90 days', 'less': 'Less', 'more': 'More',
      'no_yearly_data': 'Start using the app to see your yearly overview.',
      'productive_hours_month': 'Productive Hours per Month',
      'overview': 'Overview', 'finance_tab': 'Finance',
      // Settings
      'settings_title': 'Settings', 'language': 'Language', 'spanish': 'Español', 'english': 'English',
      'appearance': 'Appearance', 'dark_mode': 'Dark Mode', 'security': 'Security',
      'pin_protection': 'PIN Protection', 'pin_desc': 'Secure the app with a 4-digit PIN',
      'biometric': 'Biometric Auth', 'biometric_desc': 'Use fingerprint or Face ID',
      'goals': 'Goals', 'daily_water_goal': 'Daily Water Goal',
      'sleep_goal': 'Sleep Goal', 'about': 'About',
      'app_version': 'Version 1.0.0 — Personal Life OS',
      'sign_out': 'Sign Out', 'logout': 'Sign Out',
      // Finance extended
      'delete_transaction': 'Delete transaction', 'confirm_delete': 'Delete?',
      'cannot_undo': 'This action cannot be undone.',
      'add_category': 'New category', 'category_name': 'Category name',
      'expense_categories': 'Expense categories', 'income_categories': 'Income categories',
      'all_time': 'All time', 'this_month': 'This month', 'by_category': 'By category',
      'gym_days': 'Gym days', 'health_score': 'Health score',
      'log_gym': 'Log gym session', 'gym_history': 'Gym history', 'health_tips': 'Health tips',
      'gym_tab': 'Gym & Health', 'no_gym_sessions': 'No gym sessions this month',
      'days_this_month': 'days this month', 'duration_min': 'min',
      'gym_tip': 'Try to hit the gym at least 3 times this week.',
      'sleep_tip': 'Sleep 7–9 hours for optimal recovery.',
      'water_tip': 'Drink a glass of water when you wake up, before each meal, and before bed.',
      // Nutrition
      'nutrition_tab': 'Nutrition', 'my_body': 'My Body', 'weight_kg': 'Weight (kg)',
      'height_cm': 'Height (cm)', 'bmi': 'BMI', 'water_goal': 'Water goal',
      'save_metrics': 'Save metrics', 'daily_food_log': "Today's log",
      'log_food': 'Log food', 'servings': 'Servings', 'meal_time': 'Meal time',
      'today_balance': "Today's balance", 'nutrition_score': 'Nutrition score',
      'excellent': 'Excellent', 'good': 'Good', 'needs_work': 'Needs work',
      'failing_title': 'Excess today', 'missing_title': 'Not consumed today', 'weekly_treats': 'Weekly control',
      'no_food_logged': 'No food logged today.\nStart tracking what you ate!',
      'carbs_label': 'Carbohydrates', 'protein_label': 'Proteins', 'legume_label': 'Legumes',
      'veggies_label': 'Vegetables', 'fruits_label': 'Fruits', 'dairy_label': 'Dairy', 'treats_label': 'Treats',
      'portions': 'portions', 'glasses': 'glasses', 'units': 'units', 'cups': 'cups',
      'delete_food': 'Delete food entry',
      'body_normal': 'Normal', 'body_overweight': 'Overweight', 'body_obese': 'Obese', 'body_under': 'Underweight',
      // Hydration schedule
      'hydr_schedule': 'Recommended schedule', 'small_glass': 'Small glass', 'big_glass': 'Large glass',
      'bottle': 'Bottle', 'thermos': 'Thermos', 'recommended_times': 'Suggested times',
      // Skills
      'skills_title': 'Skills', 'add_skill': 'Add skill',
      'logged_today': '✓ Logged today', 'all_categories': 'All',
      'reference': 'Reference', 'skill_name': 'Skill name',
      'skill_desc': 'Description (optional)', 'target_days': 'Target days (e.g. 30, 60, 90)',
      'category': 'Category', 'no_skills': 'No skills yet.\nAdd one to get started!',
      'total_sessions': 'Total sessions', 'total_minutes': 'Total minutes', 'progress': 'Progress',
      'cat_language': 'Language', 'cat_fitness': 'Fitness', 'cat_spiritual': 'Spiritual',
      'cat_tech': 'Technology', 'cat_communication': 'Communication', 'cat_reading': 'Reading',
      'cat_other': 'Other',
      // Diary
      'diary_title': 'Daily Diary', 'diary_today': 'Today', 'diary_history': 'History',
      'diary_add': 'Add', 'diary_add_title': 'What did you do today?',
      'diary_hint': 'Write what you did...', 'diary_presets': 'Quick presets',
      'diary_empty': 'No entries yet. Start logging your day.',
      'diary_empty_today': 'Log your first moment today',
      'diary_empty_today_desc': 'Tap here to add what you did, watched or experienced today.',
      'yesterday': 'Yesterday',
      // Weekly review
      'weekly_review_title': 'Weekly Review', 'weekly_review_score': 'Weekly score',
      'weekly_review_habits': 'Habits', 'weekly_review_gym': 'Gym sessions',
      'weekly_review_sleep': 'Avg sleep', 'weekly_review_productivity': 'Productive hours',
      'weekly_review_diary': 'Moments logged',
      // Day review
      'day_review_title': 'How was your day?', 'day_score': 'Day score',
      'day_activities': 'moments today',
      // Budget
      'budget_title': 'Budget', 'budget_of': 'of', 'set_budget': 'Set budget',
      'budget_alert': 'Near limit', 'no_budget': 'No budget',
      // Activity & time types
      'act_work': 'Work', 'act_study': 'Study', 'act_exercise': 'Exercise',
      'act_learning': 'Learning', 'act_rest': 'Rest', 'act_social': 'Social',
      'act_routine': 'Routine', 'act_phone': 'Phone', 'act_entertainment': 'Entertainment',
      'act_reading': 'Reading',
      'cat_study': 'Study', 'cat_productive': 'Productive', 'cat_learning': 'Learning',
      'cat_phone': 'Phone', 'cat_entertainment': 'Entertainment', 'cat_wasted': 'Wasted',
      'cat_exercise': 'Exercise',
    },
  };
}
