// Backend validation is authoritative; Flutter also validates for usability.
export class VolunteerProfileValidationError extends Error {
  constructor(public readonly errors: string[]) {
    super('Volunteer profile validation failed.');
    this.name = 'VolunteerProfileValidationError';
  }
}

export const VEHICLE_TYPES = [
  'Motorcycle', 'Scooter', 'Car', 'Van', 'Bicycle',
  'Three-Wheeler', 'Walker / On Foot'
] as const;

export const DISTRICTS = [
  'Ampara','Anuradhapura','Badulla','Batticaloa','Colombo',
  'Galle','Gampaha','Hambantota','Jaffna','Kalutara',
  'Kandy','Kegalle','Kilinochchi','Kurunegala','Mannar',
  'Matale','Matara','Monaragala','Mullaitivu','Nuwara Eliya',
  'Polonnaruwa','Puttalam','Ratnapura','Trincomalee','Vavuniya'
] as const;

export function validateVolunteerProfile(input: unknown): string[] {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    return ['Profile must be an object.'];
  }
  const data = input as Record<string, unknown>;
  const errors: string[] = [];
  const required = ['firstName','lastName','phoneNumber','addressLine1','city','district','vehicleType'];
  const optional = ['addressLine2','vehicleNumber','nic'];
  for (const key of Object.keys(data)) {
    if (![...required,...optional].includes(key)) errors.push(`Unknown field: ${key}`);
  }
  for (const key of required) {
    if (typeof data[key] !== 'string' || !(data[key] as string).trim()) {
      errors.push(`${key} is required.`);
    }
  }
  for (const key of optional) {
    if (data[key] != null && typeof data[key] !== 'string') errors.push(`${key} must be a string.`);
  }
  const value = (key: string): string => typeof data[key] === 'string' ? (data[key] as string).trim() : '';
  for (const key of ['firstName','lastName']) {
    const v = value(key);
    if (v && (v.length < 2 || v.length > 50 || !/^[\p{L}][\p{L}\p{M} .'-]*$/u.test(v))) {
      errors.push(`${key} must be 2–50 letters/name characters.`);
    }
  }
  if (value('phoneNumber') && !/^(?:0|\+94)7\d{8}$/.test(value('phoneNumber').replace(/[\s-]/g,''))) {
    errors.push('Enter a valid Sri Lankan mobile number.');
  }
  if (value('nic') && !/^(?:\d{9}[VvXx]|\d{12})$/.test(value('nic'))) errors.push('Enter a valid NIC.');
  if (value('addressLine1') && (value('addressLine1').length < 5 || value('addressLine1').length > 150)) errors.push('Address line 1 must be 5–150 characters.');
  if (value('addressLine2').length > 150) errors.push('Address line 2 is too long.');
  if (value('city') && (value('city').length < 2 || value('city').length > 80 || !/^[\p{L}\p{M} .'-]+$/u.test(value('city')))) errors.push('Enter a valid city.');
  if (value('district') && !DISTRICTS.some(d => d.toLowerCase() === value('district').toLowerCase())) errors.push('Select a Sri Lankan district (e.g. Colombo, not Western).');
  if (value('vehicleType') && !VEHICLE_TYPES.includes(value('vehicleType') as typeof VEHICLE_TYPES[number])) errors.push('Select a valid vehicle type.');
  if (value('vehicleNumber') && !/^[A-Z0-9][A-Z0-9 -]{1,19}$/i.test(value('vehicleNumber'))) errors.push('Enter a valid vehicle number.');
  if (value('vehicleType') && !['Bicycle','Walker / On Foot'].includes(value('vehicleType')) && !value('vehicleNumber')) errors.push('Vehicle number is required for motor vehicles.');
  return errors;
}
