enum CompanyRole {
  admin(true),
  bauleiter(true),
  projektleiter(true),
  teamLeiter(true),
  projektManager(true),
  subcontractorOwner(false),
  subcontractorFieldExpert(false),
  subcontractorAsphaltExpert(false);

  final bool isInternal;

  const CompanyRole(this.isInternal);
}
