class Document {
  final int? id;
  final String? documentType;
  final String? fileName;
  final String? originalFilename;
  final String? fileUrl;
  final bool? isVerified;

  Document({
    this.id,
    this.documentType,
    this.fileName,
    this.originalFilename,
    this.fileUrl,
    this.isVerified,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      documentType: json['documentType'],
      fileName: json['fileName'],
      originalFilename: json['originalFilename'] ?? json['fileName'],
      fileUrl: json['fileUrl'] ?? json['url'] ?? json['filePath'], // Support multiple field names
      isVerified: json['isVerified'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (documentType != null) 'documentType': documentType,
      if (fileName != null) 'fileName': fileName,
      if (originalFilename != null) 'originalFilename': originalFilename,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (isVerified != null) 'isVerified': isVerified,
    };
  }
}