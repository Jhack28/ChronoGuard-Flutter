import 'package:flutter/material.dart';

void mostrarDialogoReporte(BuildContext context) {
  String fechaInicio = '', fechaFin = '', empleado = '', estado = '';
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Generar Reporte'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Fecha Inicio'), onChanged: (v) => fechaInicio = v),
            TextField(decoration: const InputDecoration(labelText: 'Fecha Fin'), onChanged: (v) => fechaFin = v),
            TextField(decoration: const InputDecoration(labelText: 'Empleado (Opcional)'), onChanged: (v) => empleado = v),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Estado (Opcional)'),
              items: ['Todos', 'Puntual', 'Tarde', 'Ausente']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => estado = v ?? '',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Generar'),
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Reporte generado (simulado)')));
          },
        ),
        TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}
