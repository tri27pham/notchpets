// supabase/functions/invite-cleanup/index.ts
// Cron: every hour — deletes expired, unaccepted invites

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { error } = await supabase
    .from("invites")
    .delete()
    .eq("accepted", false)
    .lt("expires_at", new Date().toISOString());

  if (error) {
    console.error("invite-cleanup error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }

  return new Response(JSON.stringify({ ok: true }), { status: 200 });
});
