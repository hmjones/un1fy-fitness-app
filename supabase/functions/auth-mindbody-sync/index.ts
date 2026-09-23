// Supabase Edge Function: auth-mindbody-sync
//
// Pulls the member's profile, attendance history, and LIVE "next class" straight
// from the Mindbody Public API (v6) via ClientCompleteInfo, computes stats, and
// returns them to the iOS app.
//
// Deploy:
//   supabase functions deploy auth-mindbody-sync --project-ref gzxphxqjjdickalcilrq
//
// Required function secrets:
//   supabase secrets set MINDBODY_API_KEY=...  --project-ref gzxphxqjjdickalcilrq
//   supabase secrets set MINDBODY_SITE_ID=...  --project-ref gzxphxqjjdickalcilrq
//   supabase secrets set MINDBODY_CLIENT_ID=... --project-ref gzxphxqjjdickalcilrq
//
// IMPORTANT: the iOS app encodes its request body as snake_case
// ({ access_token, refresh_token, client_id }) and decodes the response with
// convertFromSnakeCase. This function reads both snake_case and camelCase keys
// from the request so it works regardless of how the caller serializes.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function mapClassType(name: string): string {
  const lower = (name || "").toLowerCase();
  if (lower.includes("power") || lower.includes("p35")) return "Power35";
  if (lower.includes("sculpt") || lower.includes("s45")) return "Sculpt45";
  if (lower.includes("run")) return "Run Club";
  // Never echo the raw class name as a "type" — the app maps unknowns to "Other".
  return "Other";
}

// Mindbody StartDateTime values are site-local wall-clock times, often with NO
// timezone suffix (e.g. "2026-06-17T17:30:00"). Parsing the literal hour/minute
// avoids the server-timezone shift that turned 5:30 PM into 1:30.
function formatTime(iso: string): string {
  const match = (iso || "").match(/T(\d{2}):(\d{2})/);
  if (!match) return "";
  let hour = parseInt(match[1], 10);
  const minute = match[2];
  const period = hour >= 12 ? "PM" : "AM";
  hour = hour % 12;
  if (hour === 0) hour = 12;
  return `${hour}:${minute} ${period}`;
}

function computeStats(attendance: any[], upcoming: any[]) {
  const now = new Date();
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay());
  startOfWeek.setHours(0, 0, 0, 0);

  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);

  const totalClasses = attendance.length;
  let classesThisWeek = 0, classesThisMonth = 0, classesLastMonth = 0;
  const monthlyCounts: Record<string, number> = {};
  const uniqueDates = new Set<string>();

  for (const a of attendance) {
    const d = new Date(a.StartDateTime || a.startDateTime || a.date);
    const dateStr = d.toISOString().split("T")[0];
    uniqueDates.add(dateStr);
    const monthKey = `${d.getFullYear()}-${d.getMonth()}`;
    monthlyCounts[monthKey] = (monthlyCounts[monthKey] || 0) + 1;
    if (d >= startOfWeek) classesThisWeek++;
    if (d >= startOfMonth) classesThisMonth++;
    if (d >= startOfLastMonth && d <= endOfLastMonth) classesLastMonth++;
  }

  const mostClassesInMonth = Math.max(0, ...Object.values(monthlyCounts));
  const sortedDates = Array.from(uniqueDates).sort().reverse();
  let currentStreak = 0;
  let longestStreak = 0;

  const todayStr = now.toISOString().split("T")[0];
  const yesterdayStr = new Date(now.getTime() - 86400000).toISOString().split("T")[0];

  if (sortedDates.length > 0 && (sortedDates[0] === todayStr || sortedDates[0] === yesterdayStr)) {
    currentStreak = 1;
    for (let i = 1; i < sortedDates.length; i++) {
      const prev = new Date(sortedDates[i - 1]);
      const curr = new Date(sortedDates[i]);
      if ((prev.getTime() - curr.getTime()) / 86400000 === 1) {
        currentStreak++;
      } else break;
    }
  }

  if (sortedDates.length > 0) {
    const asc = [...sortedDates].reverse();
    let tempStreak = 1;
    longestStreak = 1;
    for (let i = 1; i < asc.length; i++) {
      const prev = new Date(asc[i - 1]);
      const curr = new Date(asc[i]);
      if ((curr.getTime() - prev.getTime()) / 86400000 === 1) {
        tempStreak++;
        longestStreak = Math.max(longestStreak, tempStreak);
      } else tempStreak = 1;
    }
  }

  let nextClass = null;
  if (upcoming?.length > 0) {
    const next = upcoming[0];
    const startDt = next.StartDateTime || next.startDateTime || next.date;
    const className = next.ClassDescription?.Name || next.Name || next.name || "";
    nextClass = {
      classType: mapClassType(className),
      name: className || null,
      date: startDt,
      time: formatTime(startDt),
      instructor: next.Staff?.Name || next.instructor || "",
    };
  }

  const attendanceHistory = attendance.map((a: any, i: number) => {
    const startDt = a.StartDateTime || a.startDateTime || a.date;
    const className = a.ClassDescription?.Name || a.Name || a.name || "";
    return {
      id: a.Id?.toString() || a.id || `att-${i}`,
      classType: mapClassType(className),
      name: className || null,
      date: startDt,
      time: formatTime(startDt),
      instructor: a.Staff?.Name || a.instructor || "",
    };
  });

  return { totalClasses, currentStreak, longestStreak, classesThisWeek, classesThisMonth, classesLastMonth, mostClassesInMonth, nextClass, attendanceHistory };
}

function mindBodyHeaders(accessToken: string) {
  const apiKey = Deno.env.get("MINDBODY_API_KEY")!;
  const siteId = Deno.env.get("MINDBODY_SITE_ID")!;
  return {
    "consumer-identity-token": accessToken,
    "Content-Type": "application/json",
    "Api-Key": apiKey,
    "SiteId": siteId,
  };
}

// ClientCompleteInfo returns the profile and (mostly past) visit history, but it
// does NOT reliably include the member's FUTURE bookings — which is why the
// "next class" kept coming back empty. We fetch upcoming bookings separately
// from /client/clientvisits with a forward date range; each Visit there carries
// `Name` (the class name) and `StartDateTime`.
async function fetchUpcomingBookings(accessToken: string, clientId: string | null, tzOffsetSeconds: number): Promise<any[]> {
  if (!clientId) {
    console.warn("[sync] No clientId provided; cannot fetch upcoming bookings.");
    return [];
  }

  const baseUrl = "https://api.mindbodyonline.com/public/v6";
  const now = new Date();
  // Mindbody emits the studio's wall-clock class time tagged as UTC (a 5:30 PM
  // class becomes 17:30 UTC). Express "now" in that same tagged-UTC frame using
  // the caller's offset so an evening class at a studio behind UTC isn't wrongly
  // treated as already past.
  const nowTagged = new Date(now.getTime() + tzOffsetSeconds * 1000);
  const end = new Date(now.getTime() + 60 * 86400000); // next 60 days
  const startDate = now.toISOString().split("T")[0];
  const endDate = end.toISOString().split("T")[0];

  const url = `${baseUrl}/client/clientvisits?clientId=${encodeURIComponent(clientId)}&startDate=${startDate}&endDate=${endDate}`;

  try {
    console.log("[sync] Fetching upcoming ClientVisits:", url);
    const res = await fetch(url, { headers: mindBodyHeaders(accessToken) });
    console.log("[sync] ClientVisits response status:", res.status);
    if (!res.ok) {
      const errText = await res.text();
      console.error("[sync] ClientVisits fetch failed:", errText.substring(0, 500));
      return [];
    }
    const data = await res.json();
    const visits = data.Visits || [];
    const upcoming = visits
      .filter((v: any) => {
        const d = new Date(v.StartDateTime || v.startDateTime || v.date);
        return d > nowTagged && v.LateCancelled !== true;
      })
      .sort((a: any, b: any) => {
        const da = new Date(a.StartDateTime || a.startDateTime || a.date).getTime();
        const db = new Date(b.StartDateTime || b.startDateTime || b.date).getTime();
        return da - db;
      });
    console.log("[sync] Upcoming bookings found:", upcoming.length);
    if (upcoming.length > 0) {
      console.log("[sync] Next booking:", JSON.stringify(upcoming[0]).substring(0, 400));
    }
    return upcoming;
  } catch (e) {
    console.error("[sync] ClientVisits fetch error:", (e as Error).message);
    return [];
  }
}

async function fetchMindBodyData(accessToken: string, tzOffsetSeconds: number) {
  const baseUrl = "https://api.mindbodyonline.com/public/v6";
  const headers = mindBodyHeaders(accessToken);

  let profile = null;
  let upcoming: any[] = [];
  let attendance: any[] = [];

  try {
    console.log("[sync] Fetching ClientCompleteInfo from MindBody...");
    const res = await fetch(`${baseUrl}/client/clientcompleteinfo`, { headers });
    console.log("[sync] ClientCompleteInfo response status:", res.status);

    if (res.ok) {
      const data = await res.json();
      console.log("[sync] ClientCompleteInfo data:", JSON.stringify(data).substring(0, 1000));

      profile = data.Client || null;

      const allVisits = data.Visits || [];
      const now = new Date();
      const nowTagged = new Date(now.getTime() + tzOffsetSeconds * 1000);
      attendance = allVisits.filter((v: any) => {
        const d = new Date(v.StartDateTime || v.startDateTime || v.date);
        return d <= nowTagged;
      });
      // Some sites DO surface future bookings here too — keep them as a fallback
      // for the dedicated ClientVisits fetch below.
      upcoming = allVisits
        .filter((v: any) => {
          const d = new Date(v.StartDateTime || v.startDateTime || v.date);
          return d > nowTagged;
        })
        .sort((a: any, b: any) => {
          const da = new Date(a.StartDateTime || a.startDateTime || a.date).getTime();
          const db = new Date(b.StartDateTime || b.startDateTime || b.date).getTime();
          return da - db;
        });

      console.log("[sync] Profile:", profile ? `${profile.FirstName} ${profile.LastName}` : "null");
      console.log("[sync] Past visits:", attendance.length, "Upcoming (from CompleteInfo):", upcoming.length);
    } else {
      const errText = await res.text();
      console.error("[sync] ClientCompleteInfo fetch failed:", errText.substring(0, 500));
    }
  } catch (e) {
    console.error("[sync] ClientCompleteInfo fetch error:", (e as Error).message);
  }

  return { profile, upcoming, attendance };
}

async function refreshTokens(refreshToken: string): Promise<{ access_token: string; refresh_token: string } | null> {
  const clientId = Deno.env.get("MINDBODY_CLIENT_ID")!;
  const body = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: refreshToken,
    client_id: clientId,
  });

  console.log("[sync] Attempting token refresh...");
  const res = await fetch("https://signin.mindbodyonline.com/connect/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
  });

  console.log("[sync] Refresh response status:", res.status);
  if (!res.ok) {
    const errText = await res.text();
    console.error("[sync] Token refresh failed:", errText.substring(0, 500));
    return null;
  }
  const tokens = await res.json();
  console.log("[sync] Token refresh successful. New access_token:", tokens.access_token?.substring(0, 10) + "...");
  return tokens;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const raw = await req.json();
    // The iOS app sends snake_case; accept camelCase too for safety.
    const accessToken = raw.access_token ?? raw.accessToken;
    const refreshToken = raw.refresh_token ?? raw.refreshToken ?? null;
    const requestClientId = raw.client_id ?? raw.clientId ?? null;
    // The app's UTC offset (seconds). Used to compare Mindbody's wall-clock
    // class times (tagged UTC) against the member's local "now".
    const tzOffsetSeconds = Number(raw.timezone_offset_seconds ?? raw.timezoneOffsetSeconds ?? 0) || 0;
    console.log("[sync] Request received. accessToken:", accessToken?.substring(0, 10) + "..., refreshToken:", refreshToken ? refreshToken.substring(0, 10) + "..." : "NONE", ", clientId:", requestClientId ?? "NONE");

    if (!accessToken) {
      console.error("[sync] Missing accessToken");
      return new Response(JSON.stringify({ error: "Missing accessToken" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let currentAccessToken = accessToken;
    let currentRefreshToken = refreshToken;

    // Try fetching data with current token
    let { profile, upcoming, attendance } = await fetchMindBodyData(currentAccessToken, tzOffsetSeconds);

    // If profile is null and we have a refresh token, try refreshing
    if (!profile && refreshToken) {
      console.log("[sync] Profile is null, attempting token refresh...");
      const newTokens = await refreshTokens(refreshToken);
      if (newTokens) {
        currentAccessToken = newTokens.access_token;
        currentRefreshToken = newTokens.refresh_token || refreshToken;
        const refreshed = await fetchMindBodyData(currentAccessToken, tzOffsetSeconds);
        profile = refreshed.profile;
        upcoming = refreshed.upcoming;
        attendance = refreshed.attendance;
      }
    }

    console.log("[sync] Profile found:", profile ? `${profile.FirstName} ${profile.LastName}` : "null");
    console.log("[sync] Upcoming (CompleteInfo):", upcoming.length, "Attendance:", attendance.length);

    // Prefer a dedicated forward-looking ClientVisits fetch for the next class,
    // since ClientCompleteInfo often omits future bookings. Resolve the client
    // id from the request, falling back to the profile id.
    const clientId = requestClientId?.toString() ?? profile?.Id?.toString() ?? profile?.UniqueId?.toString() ?? null;
    const upcomingBookings = await fetchUpcomingBookings(currentAccessToken, clientId, tzOffsetSeconds);
    if (upcomingBookings.length > 0) {
      upcoming = upcomingBookings;
    }

    const stats = computeStats(attendance, upcoming);

    const member = {
      clientId: profile?.Id ?? profile?.UniqueId ?? null,
      firstName: profile?.FirstName || null,
      lastName: profile?.LastName || null,
      memberSince: profile?.CreationDate || null,
      totalClasses: stats.totalClasses,
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
      classesThisWeek: stats.classesThisWeek,
      classesThisMonth: stats.classesThisMonth,
      classesLastMonth: stats.classesLastMonth,
      mostClassesInMonth: stats.mostClassesInMonth,
      monthlyGoal: 16,
      nextClass: stats.nextClass,
    };

    console.log("[sync] Returning member:", JSON.stringify(member));

    return new Response(
      JSON.stringify({
        message: "Synced successfully.",
        access_token: currentAccessToken,
        refresh_token: currentRefreshToken,
        member,
        next_class: stats.nextClass,
        attendance_history: stats.attendanceHistory,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[sync] Unhandled error:", (error as Error).message, (error as Error).stack);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
