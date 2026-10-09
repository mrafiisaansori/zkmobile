// Utilitas tanggal bersama. Label tanggal untuk tampilan memakai
// MaterialLocalizations (locale id); di sini hanya format untuk API dan
// singkatan bulan untuk sumbu grafik.

// yyyy-MM-dd, format tanggal yang diminta API.
String isoDate(DateTime d) => d.toIso8601String().substring(0, 10);

const bulanPendek = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
