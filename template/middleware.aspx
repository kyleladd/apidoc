<%@ Page Language ="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>
<script runat="server">
    public static string readFile(string filepath){
        try
        {

            using (StreamReader r = new StreamReader(filepath))
            {
                return r.ReadToEnd();
            }
        }
        catch (Exception ex) { }
        return null;
    }

    public static string GetAPIData(string json, string username){
        if (json == null) {
            return null;
        }
        try
        {
            var json_object = JsonConvert.DeserializeObject<JArray>(json);
            for (int i = json_object.Count - 1; i >= 0; i--)
            {
                if (json_object[i]["visibility"] != null){
                    var visibility_object = JsonConvert.DeserializeObject<JToken>((string)json_object[i]["visibility"]);
                    try {
                        var obj = JToken.Parse(visibility_object + "");
                        if (!obj.SelectToken("users").ToObject<List<string>>().Contains(username)) {
                            json_object.RemoveAt(i);
                        }
                    }
                    catch (Exception ex) { }
                }
            }
            return json_object.ToString();
        }
        catch (Exception ex) { }
        return null;
    }
</script>
<%
    // Deny access via web.config
    //   <location path="api_data.json">
    //   <system.web>
    //     <authorization>
    //       <deny users="*"  />
    //       <allow users ="" />
    //     </authorization>
    //   </system.web>
    // </location>
    // <location path="api_data.js">
    //   <system.web>
    //     <authorization>
    //       <deny users="*"  />
    //       <allow users ="" />
    //     </authorization>
    //   </system.web>
    // </location>
    string json = readFile(HttpContext.Current.Server.MapPath("api_data.json"));
    var json_object = GetAPIData(json, HttpContext.Current.User.Identity.Name);
    Response.ContentType = "text/javascript;charset=UTF-8";
    Response.Write("define({ \"api\": " + json_object + "});");
%>