import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/request_provider.dart';
import '../models/request.dart';

class AdminRequestList extends StatelessWidget {
  const AdminRequestList({super.key});

  @override
  Widget build(BuildContext context) {
    final requestProvider = Provider.of<RequestProvider>(context);
    final requests = requestProvider.requests;

    if (requests.isEmpty) {
      return const Center(child: Text('No hay solicitudes pendientes.'));
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final isPending = request.status == RequestStatus.pending;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            title: Text('${request.type} - Sala: ${request.moduleId}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Fecha programada: ${DateFormat('dd/MM/yyyy').format(request.date)} a las ${request.time}'),
                Text('Descripción: ${request.description}'),
                const SizedBox(height: 4),
                Text('Estado: ${request.status.name}', style: TextStyle(color: isPending ? Colors.orange : (request.status == RequestStatus.accepted ? Colors.green : Colors.red))),
                if (request.adminComment != null) Text('Comentario Admin: ${request.adminComment}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
            trailing: isPending
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Aceptar',
                        onPressed: () => _showActionDialog(context, request, RequestStatus.accepted),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Rechazar',
                        onPressed: () => _showActionDialog(context, request, RequestStatus.rejected),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  void _showActionDialog(BuildContext context, Request request, RequestStatus status) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == RequestStatus.accepted ? 'Aceptar Solicitud' : 'Rechazar Solicitud'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Añadir Comentario (Opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Provider.of<RequestProvider>(context, listen: false).updateRequestStatus(
                request.id,
                status,
                comment: controller.text.isNotEmpty ? controller.text : null,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: status == RequestStatus.accepted ? Colors.green : Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
