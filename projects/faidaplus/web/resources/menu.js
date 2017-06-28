	function changeMenuFMGS(id){
		objDaughter = document.getElementById('iDMenu'+id);
		if (objDaughter.style.display=='none'){
			objDaughter.style.display='block';
			setCookie('idmenu'+id, 'block', null);
		} else {
			if(objDaughter.style.display=='block'){
				objDaughter.style.display='none'; 
				setCookie('idmenu'+id, 'none', null);
			} 
		} 
	}
	
	function setCookie(c_name, value, expiredays) {
		var exdate = new Date();
		exdate.setDate(exdate.getDate()+expiredays);
		document.cookie = c_name + "=" +escape(value) + ((expiredays == null) ? "" : ";expires="+exdate.toGMTString());
	}
	
	function getCookie(c_name) {
		if (document.cookie.length>0) {
			c_start = document.cookie.indexOf(c_name + "=");
			if (c_start != -1) { 
				c_start = c_start + c_name.length + 1; 
				c_end = document.cookie.indexOf(";",c_start);
				if (c_end==-1) c_end = document.cookie.length;
				return unescape(document.cookie.substring(c_start, c_end));
			} 
		}
	
		return ""
	}