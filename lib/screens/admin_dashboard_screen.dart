import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../providers/data_provider.dart';
import '../models/user.dart';
import '../models/request.dart';
import '../models/module.dart';
import '../widgets/admin_request_list.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RequestProvider>(context, listen: false).listenAllRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    Widget currentTab;
    if (_currentIndex == 0) currentTab = const _StatisticsTab();
    else if (_currentIndex == 1) currentTab = const AdminRequestList();
    else if (_currentIndex == 2) currentTab = const _UsersTab();
    else currentTab = const _ModulesTab();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        actions: [
          PopupMenuButton<UserRole>(
            tooltip: 'Simular vista (Ver como...)',
            icon: const Icon(Icons.remove_red_eye),
            onSelected: (role) {
              authProvider.simulateRole(role);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: UserRole.it,
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Ver como TI'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: UserRole.user,
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Ver como Docente'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: currentTab,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Salas',
          ),
        ],
      ),
    );
  }
}

class _StatisticsTab extends StatelessWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            'Estado de Solicitudes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          SizedBox(height: 250, child: _RequestsBarChart()),
          SizedBox(height: 32),
          Text(
            'Distribución de Usuarios',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          SizedBox(height: 250, child: _UsersPieChart()),
        ],
      ),
    );
  }
}

class _RequestsBarChart extends StatelessWidget {
  const _RequestsBarChart();

  @override
  Widget build(BuildContext context) {
    final requests = Provider.of<RequestProvider>(context).requests;
    
    int pending = 0;
    int accepted = 0;
    int rejected = 0;

    for (var r in requests) {
      if (r.status == RequestStatus.pending) pending++;
      else if (r.status == RequestStatus.accepted) accepted++;
      else if (r.status == RequestStatus.rejected) rejected++;
    }

    if (requests.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (pending > accepted ? (pending > rejected ? pending : rejected) : (accepted > rejected ? accepted : rejected)).toDouble() + 5,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0: return const Text('Pendiente');
                  case 1: return const Text('Aceptada');
                  case 2: return const Text('Rechazada');
                  default: return const Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: pending.toDouble(), color: Colors.orange, width: 22, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: accepted.toDouble(), color: Colors.green, width: 22, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: rejected.toDouble(), color: Colors.red, width: 22, borderRadius: BorderRadius.circular(4))]),
        ],
      ),
    );
  }
}

class _UsersPieChart extends StatelessWidget {
  const _UsersPieChart();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        int docentes = 0;
        int ti = 0;
        int admins = 0;

        for (var doc in snapshot.data!.docs) {
          final role = doc['role'] as String?;
          if (role == 'ti') ti++;
          else if (role == 'admin') admins++;
          else docentes++;
        }

        return PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                color: Colors.blue,
                value: docentes.toDouble(),
                title: 'Docentes\n($docentes)',
                radius: 60,
                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              PieChartSectionData(
                color: Colors.green,
                value: ti.toDouble(),
                title: 'TI\n($ti)',
                radius: 60,
                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (admins > 0)
                PieChartSectionData(
                  color: Colors.purple,
                  value: admins.toDouble(),
                  title: 'Admins\n($admins)',
                  radius: 60,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role'] ?? 'docente';

            IconData roleIcon;
            Color roleColor;
            
            if (role == 'ti') {
              roleIcon = Icons.computer;
              roleColor = Colors.green;
            } else if (role == 'admin') {
              roleIcon = Icons.admin_panel_settings;
              roleColor = Colors.purple;
            } else {
              roleIcon = Icons.school;
              roleColor = Colors.blue;
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: roleColor.withAlpha(50),
                child: Icon(roleIcon, color: roleColor),
              ),
              title: Text(data['username'] ?? 'Sin nombre'),
              subtitle: Text(data['email'] ?? 'Sin correo'),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showUserOptions(context, doc.id, role),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserOptions(BuildContext context, String userId, String currentRole) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: const Text('Hacer Docente'),
                onTap: () async {
                  await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': 'docente'});
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.computer, color: Colors.green),
                title: const Text('Hacer TI'),
                onTap: () async {
                  await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': 'ti'});
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                title: const Text('Hacer Admin'),
                onTap: () async {
                  await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': 'admin'});
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar Perfil (Firestore)', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModulesTab extends StatelessWidget {
  const _ModulesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final sections = dataProvider.sections;
        
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddModuleDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Sala'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          body: sections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No hay salas configuradas'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await Provider.of<DataProvider>(context, listen: false).seedDefaultData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Salas por defecto añadidas con éxito'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Generar Salas por Defecto'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return ExpansionTile(
                      title: Text(
                        section.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      leading: const Icon(Icons.layers, color: Colors.indigo),
                      children: section.modules.map((mod) {
                        return ListTile(
                          title: Text(
                            mod.name,
                            style: TextStyle(
                              decoration: mod.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                              color: mod.isActive ? null : Colors.grey,
                            ),
                          ),
                          subtitle: Text('${mod.programs.length} programas instalados'),
                          leading: const Icon(Icons.computer),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                onPressed: () => _showEditModuleDialog(context, mod),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => _showDeleteModuleDialog(context, mod),
                              ),
                              Switch(
                                value: mod.isActive,
                                onChanged: (val) {
                                  Provider.of<DataProvider>(context, listen: false).toggleModuleStatus(mod.id, mod.isActive);
                                },
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showEditModuleDialog(BuildContext context, Module module) {
    final nameController = TextEditingController(text: module.name);
    final sectionController = TextEditingController(text: module.sectionName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Sala'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la Sala'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: sectionController,
                decoration: const InputDecoration(labelText: 'Sección o Piso'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Provider.of<DataProvider>(context, listen: false).updateModule(
                  module.id,
                  nameController.text.trim(),
                  sectionController.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteModuleDialog(BuildContext context, Module module) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Sala'),
        content: Text('¿Seguro que quieres eliminar "${module.name}" permanentemente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteModule(module.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
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
