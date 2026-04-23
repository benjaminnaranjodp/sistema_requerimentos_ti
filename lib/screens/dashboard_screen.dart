import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/request_provider.dart';
import '../models/module.dart';
import '../models/request.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/section_list_widget.dart';
import '../widgets/module_detail_widget.dart';
import '../widgets/request_form_dialog.dart';
import '../widgets/admin_request_list.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Module? _selectedModule;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final requestProvider = Provider.of<RequestProvider>(context);
    

    if (!authProvider.isAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Dashboard Departamento TI' : 'Dashboard Docente'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text(authProvider.currentUser?.username ?? '')),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen())
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.withAlpha(10),
              child: SectionListWidget(
                sections: dataProvider.sections,
                selectedModule: _selectedModule,
                onModuleSelected: (module) {
                  setState(() => _selectedModule = module);
                },
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildMainContent(requestProvider, authProvider),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 20),
                    if (isAdmin)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Modo TI Activo. Las solicitudes corresponden a la fecha del calendario.', 
                            style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(RequestProvider requestProvider, AuthProvider authProvider) {
    if (authProvider.isAdmin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Solicitudes Pendientes de TI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Expanded(child: AdminRequestList()),
        ],
      );
    }

    if (_selectedModule == null) {
      return const Center(child: Text('Selecciona una de las salas a la izquierda.'));
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
            moduleId: request.moduleId,
            date: request.date,
            time: request.time,
            type: request.type,
            description: request.description,
          );
          Provider.of<RequestProvider>(context, listen: false).addRequest(finalRequest);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitud enviada exitosamente.'), backgroundColor: Colors.green)
          );
        },
      ),
    );
  }
}
