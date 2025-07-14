// Prueba rápida de la lógica de fechas

void main() {
  // Simular la reserva que tienes
  // Entrada: 14/07/2025, Salida: 15/07/2025
  final fechaEntrada = DateTime(2025, 7, 14);
  final fechaSalida = DateTime(2025, 7, 15);
  
  print('=== PRUEBA DE LÓGICA DE FECHAS ===');
  print('Reserva: ${fechaEntrada.day}/${fechaEntrada.month} hasta ${fechaSalida.day}/${fechaSalida.month}');
  
  // Probar día 14 (entrada)
  testDia(DateTime(2025, 7, 14), fechaEntrada, fechaSalida, 'Día de entrada');
  
  // Probar día 15 (salida)
  testDia(DateTime(2025, 7, 15), fechaEntrada, fechaSalida, 'Día de salida');
  
  // Probar día 16 (después de salida)
  testDia(DateTime(2025, 7, 16), fechaEntrada, fechaSalida, 'Después de salida');
}

void testDia(DateTime dia, DateTime entrada, DateTime salida, String descripcion) {
  final despuesDeEntrada = dia.isAtSameMomentAs(entrada) || dia.isAfter(entrada);
  final antesDeSalida = dia.isBefore(salida) || dia.isAtSameMomentAs(salida);
  final enRango = despuesDeEntrada && antesDeSalida;
  
  print('\n--- $descripcion (${dia.day}/${dia.month}) ---');
  print('¿Después/igual entrada? $despuesDeEntrada');
  print('¿Antes/igual salida? $antesDeSalida');
  print('¿En rango? $enRango');
  print('Resultado: ${enRango ? "✅ MOSTRAR" : "❌ OCULTAR"}');
}
