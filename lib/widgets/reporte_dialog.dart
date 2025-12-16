import 'package:flutter/material.dart';

void mostrarDialogoReporte(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Generar Reporte'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Fecha Inicio'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Fecha Fin'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Empleado (Opcional)'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Estado (Opcional)'),
              items: [
                'Todos',
                'Puntual',
                'Tarde',
                'Ausente',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {},
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Generar'),
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reporte generado (simulado)')),
            );
          },
        ),
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
