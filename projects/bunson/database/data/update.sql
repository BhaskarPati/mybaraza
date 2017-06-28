ALTER TABLE transfer_assignments ADD time_out                    time;
ALTER TABLE transfer_assignments ADD time_in                     time;
ALTER TABLE transfer_assignments ADD closed                      boolean default false;
ALTER TABLE transfer_assignments ADD last_update                 timestamp default CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW vw_transfer_assignments AS
	SELECT drivers.driver_id, drivers.driver_name, drivers.mobile_number,
	cars.car_type_id, cars.registration_number,
	car_types.car_type_name, car_types.car_type_code,
	passangers.passanger_id, passangers.passanger_name,
	passangers.transfer_id, passangers.passanger_mobile,passangers.passanger_email,
	passangers.pickup_time, passangers.pickup, passangers.dropoff, passangers.other_preference ,
	transfer_assignments.transfer_assignment_id, 
	transfer_assignments.car_id, transfer_assignments.kms_out, transfer_assignments.kms_in,
    transfer_assignments.time_out, transfer_assignments.time_in, transfer_assignments.closed, transfer_assignments.last_update
	FROM transfer_assignments
	INNER JOIN drivers ON transfer_assignments.driver_id = drivers.driver_id
	INNER JOIN cars ON cars.car_id = transfer_assignments.car_id
	INNER JOIN car_types ON car_types.car_type_id = cars.car_type_id
	INNER JOIN passangers ON transfer_assignments.passanger_id = passangers.passanger_id;



var kmsout = $('#txtKmsOut').val();
            var timeout = $('#txt_time_out').val();
            var kmsin  = $('#txtKmsIn').val();
            var timein = $('#txt_time_in').val();
            var submit = false;
            var ok = true;
            
            if(reference == ''){
                swal("", "No Reference Selected"); ok = false; return false;
            }
            
            if(kmsout == ''){
                swal("", "Enter Kms Out"); ok = false; return false;
            }
            if(kmsin == ''){
                swal("", "Enter Kms In");  ok = false; return false;
            }
            
            if(ok){
                $.post('driverrequest', { tag:'save', reference:reference, kmsout:kmsout,  kmsin:kmsin, timeout:timeout, timein:timein, submit:submit} , function(data){
                    if(data.success == '1'){
                        swal("Success", data.message);
                        $('#txtRef,#txtKmsOut, #txtKmsIn').val('');
                        $('#panel').addClass('hidden');
                        $('#panelHeading,#panelBody').html('');
                        $('#btnSave').removeAttr('data-ref');
                    }else{
                        swal("Error!", data.message);
                    }
                },"JSON");
            }