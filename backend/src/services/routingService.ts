import { config } from '@/config/config';

export type LatLng = { lat: number; lng: number };

export type RouteEstimate = {
  distanceMeters: number;
  durationSeconds: number;
  provider: 'google' | 'haversine';
};

const toRad = (value: number): number => (value * Math.PI) / 180;
const haversineMeters = (a: LatLng, b: LatLng): number => {
  const R = 6371000; // meters
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
  return R * c;
};

export class RoutingService {
  // Fallback average speed for city delivery (in m/s); ~25 km/h
  private static fallbackSpeedMps = 25_000 / 3600;

  static async estimate(from: LatLng, to: LatLng): Promise<RouteEstimate> {
    if (config.googleMapsApiKey) {
      try {
        const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${from.lat},${from.lng}&destination=${to.lat},${to.lng}&mode=driving&key=${config.googleMapsApiKey}`;
        const resp = await (await import('node-fetch')).default(url);
        if (resp.ok) {
          const json: any = await resp.json();
          const leg = json?.routes?.[0]?.legs?.[0];
          if (leg?.distance?.value && leg?.duration?.value) {
            return {
              distanceMeters: leg.distance.value,
              durationSeconds: leg.duration.value,
              provider: 'google',
            };
          }
        }
      } catch (_) {}
    }
    // Fallback: Haversine + average speed
    const d = haversineMeters(from, to);
    const seconds = Math.max(60, Math.round(d / this.fallbackSpeedMps));
    return { distanceMeters: Math.round(d), durationSeconds: seconds, provider: 'haversine' };
  }
}

