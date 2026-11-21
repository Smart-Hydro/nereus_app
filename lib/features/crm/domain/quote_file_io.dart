/// En escritorio y en tests el archivo no se guarda en disco.
void saveQuoteBytes({
  required String filename,
  required List<int> bytes,
  required String mime,
}) {
  if (filename.isEmpty || bytes.isEmpty || mime.isEmpty) return;
}
