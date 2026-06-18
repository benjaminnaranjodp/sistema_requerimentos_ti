import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/request_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/network_provider.dart';
import '../models/module.dart';
import '../models/request.dart';
import '../models/user.dart';
import 'auth_wrapper.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/section_list_widget.dart';
import '../widgets/module_detail_widget.dart';
import '../widgets/request_form_dialog.dart';
import '../widgets/admin_request_list.dart';
import '../widgets/docente_request_list.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'chat_assistant_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Module? _selectedModule;
  int _mobileTabIndex = 0;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initListeners();
    });
  }

  void _initListeners() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);

    if (authProvider.isAdmin) {
      requestProvider.listenAllRequests();
    } else if (authProvider.currentUser != null) {
      requestProvider.listenUserRequests(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (!authProvider.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: _buildAppBar(authProvider, isAdmin),
      body: isMobile
          ? _buildMobileLayout(dataProvider, authProvider, isAdmin)
          : _buildDesktopLayout(dataProvider, authProvider, isAdmin),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatAssistantScreen()),
          );
        },
        backgroundColor: Colors.teal,
        tooltip: 'Asistente IA',
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      bottomNavigationBar: isMobile
          ? _buildBottomNav(context, isAdmin)
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(AuthProvider authProvider, bool isAdmin) {
    return AppBar(
      title: Text(
        isAdmin ? 'Panel TI' : 'Panel Docente',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.indigo.shade700,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        if (authProvider.isRealAdmin && authProvider.simulatedRole != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Tooltip(
              message: 'Volver a Administrador',
              child: IconButton(
                icon: const Icon(Icons.exit_to_app),
                color: Colors.orange.shade300,
                onPressed: () {
                  authProvider.simulateRole(null);
                },
              ),
            ),
          ),
        Consumer<NetworkProvider>(
          builder: (context, networkProvider, child) {
            final isOffline = networkProvider.isOffline;
            return Tooltip(
              message: isOffline ? 'Sin conexión (Modo Offline)' : 'Conectado a Internet',
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOffline ? Colors.grey : Colors.greenAccent,
                  boxShadow: [
                    if (!isOffline)
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                  ],
                ),
              ),
            );
          },
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
              activeColor: Colors.indigo,
              activeTrackColor: Colors.indigo.shade200,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.indigo.shade300,
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Editar datos'),
                    ],
                  ),
                ),
              ],
              offset: const Offset(0, 40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.school,
                      size: 18,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        authProvider.currentUser?.username ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar Sesión',
          onPressed: () {
            authProvider.logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthWrapper()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  

  Widget _buildMobileLayout(DataProvider dataProvider, AuthProvider authProvider, bool isAdmin) {
    if (isAdmin) {
      return _buildMobileAdminLayout(dataProvider, authProvider);
    } else {
      return _buildMobileDocenteLayout(dataProvider, authProvider);
    }
  }

  Widget _buildMobileAdminLayout(DataProvider dataProvider, AuthProvider authProvider) {
    switch (_mobileTabIndex) {
      case 0:
        return const Padding(
          padding: EdgeInsets.all(16),
          child: AdminRequestList(),
        );
      case 1:
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddModuleDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Sala'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          body: SectionListWidget(
            sections: dataProvider.sections,
            selectedModule: _selectedModule,
            isAdmin: true,
            onModuleSelected: (module) {
              setState(() {
                _selectedModule = module;
                _mobileTabIndex = 2;
              });
            },
          ),
        );
      case 2:
        return _selectedModule != null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: ModuleDetailWidget(
                  module: _selectedModule!,
                  onRequestCreated: () => _showRequestForm(context, authProvider),
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona una sala primero',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
      case 3:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: CalendarWidget(
            selectedDay: _selectedDay,
            focusedDay: _focusedDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildMobileDocenteLayout(DataProvider dataProvider, AuthProvider authProvider) {
    switch (_mobileTabIndex) {
      case 0:
        return SectionListWidget(
          sections: dataProvider.sections,
          selectedModule: _selectedModule,
          onModuleSelected: (module) {
            setState(() {
              _selectedModule = module;
              _mobileTabIndex = 1;
            });
          },
        );
      case 1:
        return _selectedModule != null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: ModuleDetailWidget(
                  module: _selectedModule!,
                  onRequestCreated: () => _showRequestForm(context, authProvider),
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona una sala primero',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
      case 2:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CalendarWidget(
                selectedDay: _selectedDay,
                focusedDay: _focusedDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DocenteRequestList(
                  userId: authProvider.currentUser?.id ?? '',
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNav(BuildContext context, bool isAdmin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).colorScheme.surface : Colors.indigo.shade50;
    final indColor = isDark ? Colors.indigoAccent.withOpacity(0.2) : Colors.indigo.shade100;
    final selectedIconColor = isDark ? Colors.indigoAccent : Colors.indigo;

    if (isAdmin) {
      return NavigationBar(
        selectedIndex: _mobileTabIndex,
        onDestinationSelected: (index) => setState(() => _mobileTabIndex = index),
        backgroundColor: bgColor,
        indicatorColor: indColor,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.list_alt),
            selectedIcon: Icon(Icons.list_alt, color: selectedIconColor),
            label: 'Solicitudes',
          ),
          NavigationDestination(
            icon: const Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room, color: selectedIconColor),
            label: 'Salas',
          ),
          NavigationDestination(
            icon: const Icon(Icons.computer_outlined),
            selectedIcon: Icon(Icons.computer, color: selectedIconColor),
            label: 'Detalle',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            selectedIcon: Icon(Icons.calendar_month, color: selectedIconColor),
            label: 'Calendario',
          ),
        ],
      );
    }

    return NavigationBar(
      selectedIndex: _mobileTabIndex,
      onDestinationSelected: (index) => setState(() => _mobileTabIndex = index),
      backgroundColor: bgColor,
      indicatorColor: indColor,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.meeting_room_outlined),
          selectedIcon: Icon(Icons.meeting_room, color: selectedIconColor),
          label: 'Salas',
        ),
        NavigationDestination(
          icon: const Icon(Icons.computer_outlined),
          selectedIcon: Icon(Icons.computer, color: selectedIconColor),
          label: 'Detalle',
        ),
        NavigationDestination(
          icon: const Icon(Icons.history),
          selectedIcon: Icon(Icons.history, color: selectedIconColor),
          label: 'Mis Solicitudes',
        ),
      ],
    );
  }

  

  Widget _buildDesktopLayout(DataProvider dataProvider, AuthProvider authProvider, bool isAdmin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        
        SizedBox(
          width: 260,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : Colors.grey.shade50,
              border: Border(right: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Salas Disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.indigo),
                          tooltip: 'Añadir Sala',
                          onPressed: () => _showAddModuleDialog(context),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SectionListWidget(
                    sections: dataProvider.sections,
                    selectedModule: _selectedModule,
                    isAdmin: isAdmin,
                    onModuleSelected: (module) {
                      setState(() => _selectedModule = module);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildMainContent(authProvider),
          ),
        ),
        
        SizedBox(
          width: 320,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(left: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  CalendarWidget(
                    selectedDay: _selectedDay,
                    focusedDay: _focusedDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isAdmin)
                    Card(
                      color: Colors.indigo.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.indigo.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Modo TI Activo.\nLas solicitudes se muestran en tiempo real.',
                                style: TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(AuthProvider authProvider) {
    if (authProvider.isAdmin) {
      if (_selectedModule != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.indigo),
                  onPressed: () => setState(() => _selectedModule = null),
                ),
                const Text(
                  'Volver a Solicitudes',
                  style: TextStyle(fontSize: 16, color: Colors.indigo, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              child: ModuleDetailWidget(
                module: _selectedModule!,
                onRequestCreated: () => _showRequestForm(context, authProvider),
              ),
            ),
          ],
        );
      }

      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solicitudes Pendientes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Expanded(child: AdminRequestList()),
        ],
      );
    }

    if (_selectedModule == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Selecciona una sala para ver sus detalles',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ModuleDetailWidget(
      module: _selectedModule!,
      onRequestCreated: () => _showRequestForm(context, authProvider),
    );
  }

  void _showRequestForm(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => RequestFormDialog(
        module: _selectedModule!,
        date: _selectedDay,
        onSubmit: (request) {
          final finalRequest = Request(
            id: request.id,
            userId: authProvider.currentUser?.id ?? 'unknown',
            userName: authProvider.currentUser?.username ?? '',
            moduleId: request.moduleId,
            date: request.date,
            time: request.time,
            type: request.type,
            description: request.description,
          );
          Provider.of<RequestProvider>(context, listen: false).addRequest(finalRequest);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud enviada exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showAddModuleDialog(BuildContext context) {
    final nameController = TextEditingController();
    final sectionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Nueva Sala'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la Sala (ej. Sala 301)'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: sectionController,
                decoration: const InputDecoration(labelText: 'Sección o Piso (ej. Piso 3)'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Nota: Si la sección no existe, se creará automáticamente.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Provider.of<DataProvider>(context, listen: false).addModule(
                  nameController.text.trim(),
                  sectionController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
