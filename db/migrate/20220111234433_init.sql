BEGIN;
CREATE TABLE public.migrations (
  version text NOT NULL,
  applied_at timestamp NOT NULL DEFAULT now()
);
ALTER TABLE public.migrations OWNER TO postgres;
COMMIT;
