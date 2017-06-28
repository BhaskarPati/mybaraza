--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: counties; Type: TABLE; Schema: public; Owner: iebc; Tablespace: 
--

CREATE TABLE counties (
    id integer NOT NULL,
    name character varying(35) NOT NULL,
    code character varying(3) NOT NULL,
    region_id integer NOT NULL,
    created timestamp(6) with time zone NOT NULL
);


ALTER TABLE public.counties OWNER TO iebc;

--
-- Name: counties_id_seq; Type: SEQUENCE; Schema: public; Owner: iebc
--

CREATE SEQUENCE counties_id_seq
    START WITH 47
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.counties_id_seq OWNER TO iebc;

--
-- Name: counties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: iebc
--

ALTER SEQUENCE counties_id_seq OWNED BY counties.id;


--
-- Name: counties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: iebc
--

SELECT pg_catalog.setval('counties_id_seq', 47, false);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: iebc
--

ALTER TABLE counties ALTER COLUMN id SET DEFAULT nextval('counties_id_seq'::regclass);


--
-- Data for Name: counties; Type: TABLE DATA; Schema: public; Owner: iebc
--

COPY counties (id, name, code, region_id, created) FROM stdin;
1	NAIROBI	001	1	2011-01-01 00:00:00+03
31	BARINGO	031	12	2011-01-01 00:00:00+03
36	BOMET	036	13	2011-01-01 00:00:00+03
40	BUNGOMA	040	15	2011-01-01 00:00:00+03
41	BUSIA	041	14	2011-01-01 00:00:00+03
29	ELGEYO/MARAKWET	029	11	2011-01-01 00:00:00+03
8	GARISSA	008	4	2011-01-01 00:00:00+03
44	HOMA BAY	044	16	2011-01-01 00:00:00+03
12	ISIOLO	012	6	2011-01-01 00:00:00+03
35	KAJIADO	035	1	2011-01-01 00:00:00+03
38	KAKAMEGA	038	14	2011-01-01 00:00:00+03
37	KERICHO	037	13	2011-01-01 00:00:00+03
23	KIAMBU	023	9	2011-01-01 00:00:00+03
4	KILIFI	004	2	2011-01-01 00:00:00+03
21	KIRINYAGA	021	10	2011-01-01 00:00:00+03
46	KISII	046	17	2011-01-01 00:00:00+03
43	KISUMU	043	16	2011-01-01 00:00:00+03
3	KWALE	003	2	2011-01-01 00:00:00+03
32	LAIKIPIA	032	12	2011-01-01 00:00:00+03
6	LAMU	006	3	2011-01-01 00:00:00+03
18	MAKUENI	018	8	2011-01-01 00:00:00+03
17	MACHAKOS	017	8	2011-01-01 00:00:00+03
10	MANDERA	010	5	2011-01-01 00:00:00+03
11	MARSABIT	011	6	2011-01-01 00:00:00+03
13	MERU	013	7	2011-01-01 00:00:00+03
45	MIGORI	045	17	2011-01-01 00:00:00+03
2	MOMBASA	002	2	2011-01-01 00:00:00+03
22	MURANG'A	022	10	2011-01-01 00:00:00+03
33	NAKURU	033	12	2011-01-01 00:00:00+03
30	NANDI	030	11	2011-01-01 00:00:00+03
34	NAROK	034	13	2011-01-01 00:00:00+03
47	NYAMIRA	047	17	2011-01-01 00:00:00+03
19	NYANDARUA	019	10	2011-01-01 00:00:00+03
20	NYERI	020	10	2011-01-01 00:00:00+03
26	SAMBURU	026	12	2011-01-01 00:00:00+03
42	SIAYA	042	16	2011-01-01 00:00:00+03
7	TAITA TAVETA	007	2	2011-01-01 00:00:00+03
5	TANA RIVER	005	3	2011-01-01 00:00:00+03
14	THARAKA NITHI	014	7	2011-01-01 00:00:00+03
27	TRANS NZOIA	027	11	2011-01-01 00:00:00+03
24	TURKANA	024	11	2011-01-01 00:00:00+03
28	UASIN GISHU	028	11	2011-01-01 00:00:00+03
39	VIHIGA	039	14	2011-01-01 00:00:00+03
9	WAJIR	009	5	2011-01-01 00:00:00+03
25	WEST POKOT	025	11	2011-01-01 00:00:00+03
16	KITUI	016	8	2011-01-01 00:00:00+03
15	EMBU	015	7	2011-01-01 00:00:00+03
\.


--
-- Name: counties_pkey; Type: CONSTRAINT; Schema: public; Owner: iebc; Tablespace: 
--

ALTER TABLE ONLY counties
    ADD CONSTRAINT counties_pkey PRIMARY KEY (id);


--
-- Name: counties_region_id; Type: INDEX; Schema: public; Owner: iebc; Tablespace: 
--

CREATE INDEX counties_region_id ON counties USING btree (region_id);


--
-- Name: counties_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: iebc
--

ALTER TABLE ONLY counties
    ADD CONSTRAINT counties_region_id_fkey FOREIGN KEY (region_id) REFERENCES regions(id) DEFERRABLE INITIALLY DEFERRED;


--
-- PostgreSQL database dump complete
--

