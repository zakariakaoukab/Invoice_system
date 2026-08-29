/// All French strings used in generated PDF invoices.
/// These are ONLY for the PDF output — all UI text is in Arabic.
class FrenchStrings {
  FrenchStrings._();

  // Company info (update with real data)
  static const companyName = 'Dar Belamri';
  static const companyTagline = 'Eau de Fleurs d\'Oranger';
  static const companyAddress = 'Maroc';
  static const companyPhone = '';
  static const companyEmail = '';

  // Invoice header
  static const invoiceTitle = 'FACTURE';
  static const invoiceNumber = 'N° Facture';
  static const invoiceDate = 'Date';
  static const issuedBy = 'Établie par';

  // Client section
  static const clientSection = 'Informations Client';
  static const clientName = 'Client';
  static const clientDetails = 'Coordonnées';

  // Table headers
  static const designation = 'Désignation';
  static const quantity = 'Quantité';
  static const unitPrice = 'Prix Unitaire (DH)';
  static const total = 'Total (DH)';

  // Totals
  static const totalToPay = 'Total à payer';

  // Footer
  static const thankYou = 'Merci pour votre confiance !';
  static const footer = 'Dar Belamri — Produits naturels d\'excellence';
}
