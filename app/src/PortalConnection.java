
import java.sql.*; // JDBC stuff.
import java.util.Properties;

public class PortalConnection {

    // For connecting to the portal database on your local machine
    static final String DATABASE = "jdbc:postgresql://localhost/portal";
    static final String USERNAME = "postgres";
    static final String PASSWORD = "suede2011";

    // For connecting to the chalmers database server (from inside chalmers)
    // static final String DATABASE = "jdbc:postgresql://brage.ita.chalmers.se/";
    // static final String USERNAME = "tda357_nnn";
    // static final String PASSWORD = "yourPasswordGoesHere";


    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);  
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }


    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode){
        try(PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO Registrations VALUES (?,?);");) {
            String idnr = student;
            String code = courseCode;
            ps.setString(1, idnr);
            ps.setString(2, code);
            ps.executeUpdate();
            return "{\"sucess\":true}";

        } catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
    }

    // Unregister a student from a course, returns a tiny JSON document (as a String)
    public String unregister(String student, String courseCode){
        try(PreparedStatement ps = conn.prepareStatement(
                "DELETE FROM Registrations WHERE student=? AND course=?;");) {
            String idnr = student;
            String code = courseCode;

            ps.setString(1, idnr);
            ps.setString(2, code);
            int res = ps.executeUpdate();
            if (res!=0) {
                ps.executeUpdate();
                return "{\"sucess\":true}";
            }
            else
                return "{\"sucess\":false, \"error\":\"student "+idnr+" is missing!}";

        } catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
    }

    // Unregister a student from a course, and introduce an SQL injection vulnerability (as a String)
    public String sqlInjection(String student, String courseCode){
        String query = "DELETE FROM Registrations WHERE student="+student+" AND course="+courseCode+";";
        try(Statement ps = conn.createStatement();) {
            int res = ps.executeUpdate(query);
            if (res!=0) {
                ps.executeUpdate(query);
                return "{\"sucess\":true}";
            }
            else
                return "{\"sucess\":false, \"error\":\"student "+student+" is missing!}";

        } catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
    }

    // Return a JSON document containing lots of information about a student, it should validate against the schema found in information_schema.json
    public String getInfo(String student) throws SQLException{
        
        try(PreparedStatement st = conn.prepareStatement(
            // replace this with something more useful
            //"SELECT jsonb_build_object('student',idnr,'name',name) AS jsondata FROM BasicInformation WHERE idnr=?"

                "SELECT jsonb_build_object('student',idnr, 'name',name, 'login',login, 'program',program, 'branch',branch," +
                        "'seminarCourses',seminarCourses, 'mathCredits',mathCredits, 'researchCredits',researchCredits, 'totalCredits',totalCredits, 'canGraduate',qualified, 'finished'," +
                        "(SELECT COALESCE(jsonb_agg(jsonb_build_object('course',course, 'code',course, 'credits',credits, 'grade',grade)), '[]') FROM FinishedCourses WHERE idnr=student), 'registered'," +
                        "(SELECT COALESCE(jsonb_agg(jsonb_build_object('course',course, 'code',course, 'status',status, 'position',place)), '[]') FROM Registrations NATURAL LEFT JOIN CourseQueuePositions WHERE idnr=student) )" +
                        "AS jsondata FROM BasicInformation, PathToGraduation WHERE idnr=? AND idnr=student"
            );){
            
            st.setString(1, student);

            ResultSet rs = st.executeQuery();
            
            if(rs.next())
              return rs.getString("jsondata");
            else
              return "{\"student\":\"does not exist :(\"}"; 
            
        } 
    }

    // This is a hack to turn an SQLException into a JSON string error message. No need to change.
    public static String getError(SQLException e){
       String message = e.getMessage();
       int ix = message.indexOf('\n');
       if (ix > 0) message = message.substring(0, ix);
       message = message.replace("\"","\\\"");
       return message;
    }
}