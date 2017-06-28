package dewcis.DB;

import java.sql.*;

public class DTable {

	Statement st, autost;
	ResultSet rs;
	ResultSetMetaData metaData;

	boolean isEdit = false;
	boolean isAddNew = false;

	public DTable(Connection db, String sql) {
		
		// create a record set
		try {
			st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			rs = st.executeQuery(sql);
			rs.next();

			metaData = rs.getMetaData();
		} catch(SQLException ex) {
			System.out.println("SQLException SQL creation : " + ex);
		}
	}

	public void recAdd() {
		if (!isEdit) {
			isAddNew = true;
			try {
				rs.moveToInsertRow();
			} catch (SQLException ex) {
				System.out.println("New row error : " + ex);
			}
		}
	}

	public void recEdit() {
		if(!isAddNew) isEdit = true;
	}

 	public void recUpdate() {
		try {
			if(isAddNew) rs.insertRow();
			if(isEdit) rs.updateRow();

			isAddNew = false;
			isEdit = false;
    	} catch (SQLException ex) {
        	System.out.println("Edit row error : " + ex);
    	}
	}

	public String readData(String fieldname) {
		String fielddata = "";
		try {
			fielddata = rs.getString(fieldname);
			if(fielddata == null) fielddata = "";
		} catch (SQLException ex) {
        	System.out.println("Edit row error : " + ex);
    	}
	
		return fielddata;
	}

	public String hiddenData() {
		String data = "";
		try {
			int j = metaData.getColumnCount();
	
			for(int i = 1; i <= j; i++) {
				if(rs.getString(i) != null) {
					data += "<input type=\"hidden\" name=\"" + metaData.getColumnName(i) + "\" value=\"";
					data += rs.getString(i) + "\"/>\n";
				}
			}
		} catch (SQLException ex) {
        	System.out.println("Edit row error : " + ex);
    	}

		return data;
	}

	public String recUpdate(Connection db, String tablename, String autofield) {
		String autoid = null;
		String autosql = "select nextval('" + tablename + "_" + autofield + "_seq');";
		try {
			Statement autost = db.createStatement();
			ResultSet autors = autost.executeQuery(autosql);
			autors.next();
			autoid = autors.getString(1);
			autors.close();		
			updateRow(autofield, autoid);

			// Update all field
			recUpdate();
    	} catch (SQLException ex) {
        	System.out.println("Get row error : " + ex);
    	}

		System.out.println(autoid);

		return autoid;
	}

	public void updateRow(String fname, String fvalue) {
		int type;
		
        try {
			int columnindex = rs.findColumn(fname);
		    if(fvalue.length()<1) {
				rs.updateNull(fname);
		    } else {
				type = metaData.getColumnType(columnindex);
	
				// System.out.println(fname + " = " + fvalue + " type = " + type);
				switch(type) {
        			case Types.CHAR:
        			case Types.VARCHAR:
        			case Types.LONGVARCHAR:
            			rs.updateString(fname, fvalue);
						break;
       				case Types.BIT:
						if(fvalue.equals("true")) rs.updateBoolean(fname, true);
						else rs.updateBoolean(fname, false);
						break;
        			case Types.TINYINT:
        			case Types.SMALLINT:
        			case Types.INTEGER:
						int ivalue = Integer.valueOf(fvalue).intValue();
						rs.updateInt(fname, ivalue);
						break;
					case Types.NUMERIC:
		        	case Types.BIGINT:
						long lvalue = Long.valueOf(fvalue).longValue();
						rs.updateLong(fname, lvalue);
						break;
		        	case Types.FLOAT:
		        	case Types.DOUBLE:
					case Types.REAL:
						double dvalue = Double.valueOf(fvalue).doubleValue();
						rs.updateDouble(fname, dvalue);
						break;
		        	case Types.DATE:
						java.sql.Date dtvalue = Date.valueOf(fvalue);
						rs.updateDate(fname, dtvalue);
						break;
		        	case Types.TIME:
						java.sql.Time tvalue = Time.valueOf(fvalue);
						rs.updateTime(fname, tvalue);
						break;
					case Types.TIMESTAMP:
						java.sql.Timestamp tsvalue = java.sql.Timestamp.valueOf(fvalue);
						rs.updateTimestamp(fname, tsvalue);
						break;
				}
		   	}
        } catch (SQLException ex) {
        	System.out.println("The SQL Exeption on " + fname + " : " + ex);
        }
	}

	public void recDelete() {
		try {
			rs.deleteRow();
		} catch (SQLException ex) {
       		System.out.println("Delete row error : " + ex);
		}
	}

	public void recCancel() {
		isAddNew = false;
		isEdit = false;
	}

}
