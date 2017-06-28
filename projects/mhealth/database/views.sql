CREATE VIEW vw_messages AS
	SELECT languages.language_id, languages.language_name, message_category.message_category_id, message_category.message_category_name, 
			messages.message_id, messages.message_code, messages.is_before_delivery, messages.is_after_delivery, messages.week_number, messages.message_order, 
			messages.frequency, messages.frequency_interval, messages.is_weekly_interval, messages.is_partner, messages.message_data, messages.details
	FROM messages INNER JOIN languages ON messages.language_id = languages.language_id
		INNER JOIN message_category ON messages.message_category_id = message_category.message_category_id;

CREATE VIEW vw_message_schedule AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.mobile_number, entitys.is_patient_enrolled, entitys.partner_name, 
		entitys.partner_mobile_no, entitys.is_partner_enrolled,
		messages.message_id, messages.message_category_id, messages.language_id, messages.message_code,
		messages.is_before_delivery, messages.is_after_delivery, messages.is_partner,
		message_schedule.message_schedule_id, message_schedule.sms_id, message_schedule.schedule_date, 
		message_schedule.schedule_time, message_schedule.message, message_schedule.details
	FROM message_schedule INNER JOIN entitys ON message_schedule.entity_id = entitys.entity_id
		INNER JOIN messages ON message_schedule.message_id = messages.message_id;


		

