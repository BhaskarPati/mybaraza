ALTER TABLE period_license ADD qreturn_number integer default 0 not null;
ALTER TABLE period ADD return_deadline  DATE;

ALTER TABLE client_license_doc ADD notice_id  NUMBER(*,0);
ALTER TABLE client_license_doc ADD FOREIGN KEY (notice_id) REFERENCES notice (notice_id);

ALTER TABLE period ADD is_compliance CHAR(1 BYTE) DEFAULT '0' NOT NULL;
