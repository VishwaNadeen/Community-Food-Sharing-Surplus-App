
export class VolunteerProfileValidationError extends Error {
  constructor(public readonly errors: string[]) {
    super('Volunteer profile validation failed.');
    this.name = 'VolunteerProfileValidationError';
  }
}
