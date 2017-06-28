<%
String attr = request.getParameter("tag");
System.out.println(attr);
%>
<!-- BEGIN SIDEBAR -->
<!-- DOC: Set data-auto-scroll="false" to disable the sidebar from auto scrolling/focusing -->
<!-- DOC: Change data-auto-speed="200" to adjust the sub menu slide up/down speed -->
<div class="page-sidebar navbar-collapse collapse">
    <!-- BEGIN SIDEBAR MENU -->
    <ul class="page-sidebar-menu   " data-keep-expanded="false" data-auto-scroll="true" data-slide-speed="200">
        <li class="nav-item" id="dash">
            <a href="dashboard?tag=dash" class="nav-link nav-toggle">
                <i class="icon-home"></i>
                <span class="title">Dashboard</span>
                <span class="selected"></span>
                <span class="arrow open"></span>
            </a>
        </li>
        <li class="nav-item" id="orders">
            <a href="orders?tag=orders" class="nav-link nav-toggle">
                <i class="icon-basket"></i>
                <span class="title">Orders</span>
                <span class="arrow"></span>
            </a>
        </li>
        <li class="nav-item" id="statement">
            <a href="statement?tag=statement"  class="nav-link nav-toggle">
                <i class="icon-notebook"></i>
                <span class="title">Statements</span>
                <span class="arrow"></span>
            </a>
        </li>
    
        <li class="nav-item  " id="settings">
        	<a href="javascript:;" class="nav-link nav-toggle "> <i class="icon-settings"></i></i><span class="title">Edit Settings</span><span class="arrow open"></span></a>
        	<ul class="sub-menu"  data-keep-expanded="false" >
        		<li id="details">
        			<a href="settings?view=15:0:0&data=103&tag=details"> <i class="fa fa-arrow-right"></i> <span>Edit Contact Details</span></a>
        		</li>
        		<li id="son">
        			<a href="settings?view=15:0:1&data=103&tag=son"> <i class="fa fa-arrow-right"></i> <span>Edit SON Details</span></a>
        		</li>
                <li id="town">
        			<a href="settings?view=15:1&data=&tag=town"> <i class="fa fa-arrow-right"></i> <span>Edit Delivery Town</span></a>
        		</li>
            </ul>
        </li>
        <%-- <li class="nav-item  ">
            <a href="help.jsp" class="nav-link nav-toggle">
                <i class="icon-question"></i>
                <span class="title">Help</span>
                <span class="arrow"></span>
            </a>
        </li> --%>
    </ul>
    <!-- END SIDEBAR MENU -->
</div>
<!-- END SIDEBAR -->
