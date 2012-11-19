# PERL
#-----------------------------------------------------------------------------
# GrokAdmin.pl
# 
# Simple administrative interface to Grok.
#-----------------------------------------------------------------------------
# Author: Dan Calle
# Revision: George Liu
#
#-----------------------------------------------------------------------------
# Date: 18 Mar 2010
#
#-----------------------------------------------------------------------------
# Comments:
#   
# 23mar10 - v.01: 
# - modified sql statement in getOntology to capture the display_name from the table_schema table.
# - modified the html statement to display the table_schema.display_name in displayOntologyManager()
# 
# 08apr10 - v.02:
# - basic insert data_source complete.  need to add the oali entry and associated linkes.
# - on updating: 1. create new *_atttr_inst entry
#                2. create new OALI entry for #1
#                3. soft delete previous OALI entry
#                4. EC: add entry to DB_ACTION table
#
# 
# 07jun - v.06:
# - can produce ontology tree (classObject & attrbutes)
# - corresponds with grokAdmin-v06.js
#-----------------------------------------------------------------------------

use CGI qw(-nph);
use CGI::Carp(fatalsToBrowser);
use Data::Dumper;
use Date::Calc qw(check_date Today);
use MITRE::ITConfig;
use MITRE::DBHandler;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);

my $DATA_SOURCE => 'Data_Source';
my $GROK_USER => 'Grok_User';

my $TABLE_SCHEMA;
my $UNCLASSIFIED = '3E3A8383-8469-4847-8485-C6761B09FD46';

#use grokUser;

my $cgi = new CGI();

# print $cgi->header();

unless (local $db = new DBHandler($ITConfig::grokDSN)) {
    mydie('Unable to connect to the Grok database!');
}

my $op = $cgi->param('op');

my $entity_or_link = $cgi->param('entity_or_link');
my $display_name = $cgi->param('display_name');
my $object_ID = $cgi->param('object_ID');
my $new_object_name = $cgi->param('new_object_name');
my $attr_display_name = $cgi->param('attr_display_name');
my $attr_table_ID = $cgi->param('attr_table_ID');
my $display_order = $cgi->param('display_order');
my $attribute_descr = $cgi->param('attribute_descr');
my $attribute_ID = $cgi->param('attribute_ID');
my $entity_ID = $cgi->param('entity_ID');
my $attribute_display_order = $cgi->param('attribute_display_order');
my $attribute_description = $cgi->param('attribute_description');

###### DATA SOURCES CREATION PARAMETERS
my $data_sources_name = $cgi->param('data_sources_name');
my $data_sources_description = $cgi->param('data_sources_description');
my $data_sources_gathering_mechanism = $cgi->param('data_sources_gathering_mechanism');
my $data_sources_priority = $cgi->param('data_sources_priority');
my $data_sources_URL = $cgi->param('data_sources_URL');
my $data_sources_date_identified = $cgi->param('data_sources_date_identified');
my $dsNameAttrInst_ID = $cgi->param('dsNameAttrInst_ID');
my $dsDescriptionAttrInst_ID = $cgi->param('dsDescriptionAttrInst_ID');
my $dsGatheringMechanismAttrInst_ID = $cgi->param('dsGatheringMechanismAttrInst_ID');
my $dsPriorityAttrInst_ID = $cgi->param('dsPriorityAttrInst_ID');
my $dsURLAttrInst_ID = $cgi->param('dsURLAttrInst_ID');
my $dsDate_IdentifiedAttrInst_ID = $cgi->param('dsDate_IdentifiedAttrInst_ID');
my @dsAssignEngineer = $cgi->param('data_sources_assign_engineer');
my @dsFreeAssignEngineer = $cgi->param('free_assign_engineer');

my $assignEngineerInst_ID = $cgi->param('assignEngineerInst_ID');
my $dataSourceInst_ID = $cgi->param('dataSourceInst_ID');

###### GROK USERS CREATION PARAMETERS
my $grok_users_login_name = $cgi->param('grok_users_login_name');
my $grok_users_real_name = $cgi->param('grok_users_real_name');
my $grok_users_email_address = $cgi->param('grok_users_email_address');
my $grok_users_LAN_account = $cgi->param('grok_users_LAN_account');

my $guLoginNameAttrInst_ID = $cgi->param('guLoginNameAttrInst_ID');
my $guRealNameAttrInst_ID = $cgi->param('guRealNameAttrInst_ID');
my $guEmailAddressAttrInst_ID = $cgi->param('guEmailAddressAttrInst_ID');
my $guLANAccountAttrInst_ID = $cgi->param('guLANAccountAttrInst_ID');

### OALI MODULE VARIABLES ###
my $oaliObjectInst_ID = '';
my $oaliAttrInst_ID = '';
my $oaliAttr_ID = '';
my $oaliSrcEntityInst_ID = '';
my $oaliDateOfInformation = '';
my $oaliConfidence = '';
my $oaliDerivedFlag = '';
my $oaliDeletedFlag = '';
my $oaliClass_ID = '';
my $oaliObject_id = '';


print "Content-Type: text/xml\n\n";

# print &buildHeader;

if ($op eq 'ontology') {
				# print "<div class='container'>" . displayOntologyManager() . "</div>";
		print displayOntologyManager();
}
elsif ($op eq 'add_object') {
    my $result_html = createObject($entity_or_link, $display_name);
    print "<div class='message'>" . $result_html . "</div>\n";
    print "<div class='container'>" . displayOntologyManager() . "</div>";
}
elsif ($op eq 'confirm_delete_object') {
    print "<div class='container'>" . displayDeleteObjConfirmation($object_ID) . "</div>";
}
elsif ($op eq 'delete_object_attribute') {
    my $result_html = deleteObjectAttribute($attribute_ID);
    print "<div class='message'>" . $result_html . "</div>\n";
    print "<div class='container'>" . displayOntologyManager() . "</div>";
}
elsif ($op eq 'delete_object') {
    my $result_html = deleteObject($object_ID);
    print "<div class='message'>" . $result_html . "</div>\n";
    print "<div class='container'>" . displayOntologyManager() . "</div>";
}
elsif ($op eq 'update_object_attribute') {
    print "<div class='container'>" . displayUpdateObjectAttributeInterface($attribute_ID) . "</div>";
}
elsif ($op eq 'edit_object_attribute') {
    print "<div class='container'>" . displayEditObjectAttributeInterface($attribute_ID) . "</div>";
}
elsif ($op eq 'confirm_delete_object_attribute') {
    print "<div class='container'>" . displayDeleteObjectAttributeConfirmationInterface($attribute_ID) . "</div>";
}
elsif ($op eq 'get_new_object_name') {
    print "<div class='container'>" . displayNewObjNameInterface($object_ID) . "</div>";
}
elsif ($op eq 'get_new_attr_info') {
    print "<div class='container'>" . displayNewAttrInterface($object_ID) . "</div>";
}
elsif ($op eq 'create_attribute') {
    my $result_html = createAttribute($object_ID, $attr_display_name, $attr_table_ID, $display_order, $attribute_descr);
    print "<div class='message'>" . $result_html . "</div>\n";
    print "<div class='container'>" . displayOntologyManager() . "</div>";
}
elsif ($op eq 'rename_object') {
    my $result_html = renameObject($object_ID, $new_object_name);
    print "<div class='message'>" . $result_html . "</div>\n";
    print "<div class='container'>" . displayOntologyManager() . "</div>";
}
#
# BEGIN DATA SOURCES OPERATIONS ##############################
elsif ($op eq 'dataSources') {
    print "<div class='container'>" . displayDataSourcesManager('Data_Source') . "</div>";
}
elsif ($op eq 'add_data_sources') {
    my $result_html = createEntityInst ($data_sources_name, $data_sources_description, $data_sources_gathering_mechanism, $data_sources_priority, $data_sources_URL, $data_sources_date_identified, $object_ID) . "</div>";
    $result_html .= linkDataSourceToAssignEngineers ($object_ID, $data_sources_name, @dsAssignEngineer);
    print "<div class='message'>" . $result_html . "</div>\n";
    print "<div class='container'>" . displayDataSourcesManager('Data_Source') . "</div>";
}
elsif ($op eq 'update_data_sources') {
    print "<div class='container'>" . displayUpdateDataSourcesManager($entity_ID, $object_ID) . "</div>";
}
elsif ($op eq 'update_data_source_attributes') {
    my $result_html = updateDataSources( $data_sources_name, $dsNameAttrInst_ID, $data_sources_description, $dsDescriptionAttrInst_ID, $data_sources_gathering_mechanism, $dsGatheringMechanismAttrInst_ID, $data_sources_priority, $dsPriorityAttrInst_ID, $data_sources_URL, $dsURLAttrInst_ID, $data_sources_date_identified, $dsDate_IdentifiedAttrInst_ID) . "</div>";
    $result_html .= linkDataSourceToAssignEngineers ($object_ID, $data_sources_name, @dsFreeAssignEngineer);
    print "<div class='message'>" . $result_html . "</div>\n";
    print "<a href='$ENV{'SCRIPT_NAME'}?op=dataSources'>BACK</a> to Data Sources Manager<br>";
}
elsif ($op eq 'remove_assign_engineer') {
    print "<div class='container'>" . removeAssignEngineer($assignEngineerInst_ID, $dataSourceInst_ID) . "</div>";
}
elsif ($op eq 'confirm_remove_assign_engineer') {
    print "<div class='container'>" . displayConfirmRemoveAssignEngineerManager($assignEngineerInst_ID, $dataSourceInst_ID) . "</div>";
}
elsif ($op eq 'confirm_delete_data_sources') {
    print "<div class='container'>" . displayConfirmDeleteDataSourcesManager($entity_ID) . "</div>";
}
elsif ($op eq 'delete_entity_instance') {
    print "<div class='container'>" . deleteEntityInstance($entity_ID) . "</div>";
    print "<div class='container'>" . displayDataSourcesManager('Data_Source') . "</div>";
}
# END DATA SOURCES OPERATIONS ##############################
#
# BEGIN GROK USERS OPERATIONS ##############################
elsif ($op eq 'grokUsers') {
    print "<div class='container'>" . displayGrokUsersManager('Grok_User') . "</div>";
}
elsif ($op eq 'add_grok_users') {
    my $result_html = createGrokUserEntityInst ($grok_users_login_name, $grok_users_real_name, $grok_users_email_address, $grok_users_LAN_account, $object_ID) . "</div>";
    print "<div class='message'>" . $result_html . "</div>\n";
    print "<div class='container'>" . displayGrokUsersManager('Grok_User') . "</div>";
}
elsif ($op eq 'update_grok_users') {
    print "<div class='container'>" . displayUpdateGrokUsersManager($entity_ID, $object_ID) . "</div>";
}
elsif ($op eq 'update_grok_users_attributes') {
    print "<div class='container'>" .  updateGrokUsers( $grok_users_login_name, $guLoginNameAttrInst_ID, $grok_users_real_name, $guRealNameAttrInst_ID, $grok_users_email_address, $guEmailAddressAttrInst_ID, $grok_users_LAN_account, $guLANAccountAttrInst_ID ) . "</div>";
    print "<a href='$ENV{'SCRIPT_NAME'}?op=grokUsers'>BACK</a> to Grok Users Manager<br>";
}
elsif ($op eq 'confirm_delete_grok_users') {
    print "<div class='container'>" . displayConfirmDeleteGrokUsersManager($entity_ID) . "</div>";
}
elsif ($op eq 'delete_grok_user_entity_instance') {
    print "<div class='container'>" . deleteEntityInstance($entity_ID) . "</div>";
    print "<div class='container'>" . displayGrokUsersManager('Grok_User') . "</div>";
}
# END GROK USERS OPERATIONS ##############################
elsif ($op eq 'dataClassification') {
    print "<div class='container'>" . displayDataClassificationManager() . "</div>";
}
elsif ($op eq 'transliterateRE') {
    print "<div class='container'>" . displayTransliterateREManager() . "</div>";
}
elsif ($op eq 'editLanguages') {
    print "<div class='container'>" . displayLanguageManager() . "</div>";
}
elsif ($op eq 'importExport') {
    print "<div class='container'>" . displayImportExportInterface() . "</div>";
} else {
    print "<div class='container'>" . displayMainInterface() . "</div>";
}
print $cgi->end_html;

######################################## subroutines ##########################################

sub debug {
    my $msg = shift @_;
    print "<div class='message'>" . $msg . "</div>\n";
}


sub buildHeader {
    my $html = $cgi->start_html(-title=>'MITRE DEPOT',
                            -style=>{'src'=>'style.css'},
                            -BGCOLOR=>'lightblue')
    	. qq(<h1>Grok Admin</h1>);
    return $html;
}

sub displayMainInterface {
    my $html = qq(
    	From here you may wish to:<br>
    	<a href="$ENV{'SCRIPT_NAME'}?op=ontology">View/Edit the Ontology</a><br>
    	<a href="$ENV{'SCRIPT_NAME'}?op=dataSources">View/Edit the Data Sources</a><br>
    	<a href="$ENV{'SCRIPT_NAME'}?op=grokUsers">View/Edit the Grok Users</a><br>
    	<a href="$ENV{'SCRIPT_NAME'}?op=dataClassification">View/Edit Data Classifications</a><br>
    	<a href="$ENV{'SCRIPT_NAME'}?op=transliterateRE">View/Edit Transliteration Regular Expressions</a><br>
    	<a href="$ENV{'SCRIPT_NAME'}?op=editLanguages">View/Edit Languages</a><br>
    	<a href="$ENV{'SCRIPT_NAME'}?op=importExport">Import/Export<a/> 
    );
    
    return $html;
}

######################################## ONTOLOGY SUBROUTINES ##################################




sub ssisplayOntologyManager {

	my $row_html = qq(
<html><body>
[
[ '1', 'classObject', 'Abbreviation', 'a', 'a', 'a', 'a'],
[ '2', 'attribute', 'Technical Remarks', 'Tech Remarks', 'String', 'tr desc', '1' ],
[ '3', 'attribute', 'Updated By', 'update by', 'XML', 'xml desc', '2' ],
[ '4', 'attribute', 'Vetted By', 'vetted by', 'Bin', 'bin desc', '3' ],
[ '5', 'classObject', 'Adjective', 'b', 'b', 'b', 'b' ],
[ '6', 'attribute', 'Description', 'Tech Remarks', 'String', 'string desc', '11' ],
[ '7', 'attribute', 'Technical Remarks', 'more tech remarks', 'float', 'float desc', '12' ],
[ '8', 'attribute', 'Updated By', 'Tech Remarks', 'CGRect', 'cgrect desc', '13' ],
[ '9', 'attribute', 'Vetted By', 'Tech Remarks', 'NSArray', 'nsarray desc', '14' ]
]
	);

return $row_html;
}

sub xmlDisplayOntologyManager {
			my $row_html = qq(<?xml version="1.0" encoding="ISO-8859-1"?>);
			$row_html .= qq(<html><body>);
		  $row_html .= qq(<classRec id="1">);
			$row_html .= qq(<nodeID>0</nodeID>);
			$row_html .= qq(<key>classObject</key>);
			$row_html .= qq(<value>Abbreviation</value>);
			$row_html .= qq(<displayName>a</displayName>);
			$row_html .= qq(<type>a</type>);
			$row_html .= qq(<description>a</description>);
			$row_html .= qq(<displayOrder>a</displayOrder>);
		$row_html .= qq(</classRec>);
		$row_html .= qq(<classRec id="2">);
			$row_html .= qq(<nodeID>1</nodeID>);
			$row_html .= qq(<key>attribute</key>);
			$row_html .= qq(<value>Technical Remarks</value>);
			$row_html .= qq(<displayName>Tech Remarks</displayName>);
			$row_html .= qq(<type>String</type>);
			$row_html .= qq(<description>tr desc</description>);
			$row_html .= qq(<displayOrder>1</displayOrder>);
		$row_html .= qq(</classRec>);
		$row_html .= qq(<classRec id="3">);
			$row_html .= qq(<nodeID>2</nodeID>);
			$row_html .= qq(<key>attribute</key>);
			$row_html .= qq(<value>Updated By</value>);
			$row_html .= qq(<displayName>updated by</displayName>);
			$row_html .= qq(<type>XML</type>);
			$row_html .= qq(<description>xml desc</description>);
			$row_html .= qq(<displayOrder>2</displayOrder>);
		$row_html .= qq(</classRec>);

		return $row_html;
}

sub cleanString {
		my $str = shift @_;
		$str =~ s/\r//g;
		$str =~ s/\r\n//g;
		$str =~ s/\n\r//g;
		$str =~ s/\n//g;

		return $str;
}

sub displayOntologyManager {

    my @ontology = getOntology();
    my $table_schema = getTableSchema();
    my $entity_inst_table_ID = $table_schema->{'ENTITY_INST'};
    my $link_inst_table_ID = $table_schema->{'LINK_INST'};

		my $nodeID = 0;
		my $classRecID = 0;

		# mydie( Dumper(\@ontology) );

		my $row_html = qq(<?xml version="1.0" encoding="ISO-8859-1"?>\n);

		$row_html .= qq(<html><body>\n);
    foreach $object (@ontology) {

			$nodeID++;
			$classRecID++;

		  $row_html .= qq(<classRec id="$classRecID">\n);
					$row_html .= qq(<nodeID>$nodeID</nodeID>\n);
					$row_html .= qq(<key>classObject</key>\n);
					$row_html .= qq(<value>$object->{'display_name'}</value>\n);
					$row_html .= qq(<displayName> </displayName>\n);
					$row_html .= qq(<type> </type>\n);
					$row_html .= qq(<description> </description>\n);
					$row_html .= qq(<displayOrder> </displayOrder>\n);
		  $row_html .= qq(</classRec>\n\n);

    	foreach $attribute (@{$object->{'attributes'}}) {

				if ( length($attribute->{'displayName'}) != 0 ) {
					$nodeID++;
					$classRecID++;
		  		$row_html .= qq(<classRec id="$classRecID">\n);
							$row_html .= qq(<nodeID>$nodeID</nodeID>\n);
							$row_html .= qq(<key>attribute</key>\n);
							$row_html .= qq(<value>$attribute->{'physicalName'}</value>\n);
							$row_html .= qq(<displayName>$attribute->{'displayName'}</displayName>\n);
							$row_html .= qq(<type>$attribute->{'table_type'}</type>\n);
							$row_html .= qq(<description>$attribute->{'description'}</description>\n);
							$row_html .= qq(<displayOrder>$attribute->{'displayOrder'}</displayOrder>\n);
		  		$row_html .= qq(</classRec>\n\n);
				}

    	}


    }
		
		##$row_html .= qq(</body></html>);

    return $row_html;
}

sub getOntology {
    my @ontology;
    
    my $table_schema = getTableSchema();
    
    # All entity classes and associated attributes
    # added sql join clause: left outer join (ATTRIBUTE join TABLE_SCHEMA on ATTRIBUTE.attr_table_id = TABLE_SCHEMA.id) gpl 23mar10
    my $sql = qq(
    select OBJECT.ID, OBJECT.DISPLAY_NAME as object, OBJECT.TABLE_ID, attribute.ID as attr_ID, 
    	attribute.PHYSICAL_NAME as attr_phys, ATTRIBUTE.DISPLAY_NAME as attr_disp,  
    	ATTRIBUTE.DESCR as attr_descr, ATTRIBUTE.DISPLAY_ORDER as attr_displayOrder,
    TABLE_SCHEMA.display_name as table_type
    from object
    left outer join ATTRIBUTE on OBJECT.ID = ATTRIBUTE.OBJECT_ID
    left outer join TABLE_SCHEMA on ATTRIBUTE.attr_table_id = TABLE_SCHEMA.id
    where OBJECT.DELETED_FLAG = 0 and ( ATTRIBUTE.ID is null or ATTRIBUTE.DELETED_FLAG = 0)
    order by OBJECT.DISPLAY_NAME, attribute.display_order, attr_phys
    );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to retrieve ontology info from the database: " . $db->Error) if $db->Error;

		# mydie( Dumper(\@rs) );

    foreach $row (@rs) {
    	unless (scalar(@ontology) && $ontology[$#ontology]->{'ID'} eq $row->{'ID'}) {
    		my $object = {};
    		$object->{'ID'} = $row->{'ID'};
    		$object->{'display_name'} = $row->{'object'};
    		$object->{'table_ID'} = $row->{'TABLE_ID'};
    		$object->{'attributes'} = ();
    		push @ontology, $object;
    	}
    	my $attribute = {};
    	$attribute->{'ID'}				= $row->{'attr_ID'},
    	$attribute->{'physicalName'}	= $row->{'attr_phys'},
    	$attribute->{'displayName'}	= $row->{'attr_disp'},
    	$attribute->{'description'}		= $row->{'attr_descr'},
    	$attribute->{'table_type'}		= $row->{'table_type'},
    	$attribute->{'displayOrder'}		= $row->{'attr_displayOrder'},
    	push @{$ontology[$#ontology]->{'attributes'}}, $attribute;
    };
    return @ontology;
}

# Sets global (to this script) $TABLE_SCHEMA
#
sub getTableSchema {
    return $TABLE_SCHEMA if defined $TABLE_SCHEMA;
    my $sql = qq(select ID, TABLE_NAME from table_schema where DELETED_FLAG = 0);
    
    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to retrieve table info from the database: " . $db->Error)
    	if $db->Error;
    	
    foreach $row (@rs) {
    	$TABLE_SCHEMA->{$row->{'TABLE_NAME'}} = $row->{'ID'};
    	$TABLE_SCHEMA->{$row->{'ID'}} = $row->{'TABLE_NAME'};
    }
    return $TABLE_SCHEMA;
}	


sub createObject {
    my ($entity_or_link, $display_name) = @_;

    my $physical_name = $display_name;
    $physical_name =~ s/\W/_/g;
    $display_name =~ s/'/''/g;

    my $table_schema = getTableSchema();
    my $table_ID = $entity_or_link eq 'entity' ? 
    		$table_schema->{'ENTITY_INST'} : $table_schema->{'LINK_INST'};

    return qq(<font color='red'>ERROR: Object with this name already exists</font>)
    	if detectObjectCollision($table_ID, $display_name);
    
    my $sql = qq(
    	INSERT INTO object 
    	(ID, PHYSICAL_NAME, DISPLAY_NAME, TABLE_ID, DELETED_FLAG, CLASS_ID)
    	VALUES (NEWID(), '$physical_name', '$display_name', '$table_ID', 0, '$UNCLASSIFIED')
    );

    $db->ExecuteSQL($sql);
    mydie("Unable to create new object class: " . $db->Error) if $db->Error;
    
    return qq(Object $display_name successfully created.);
}

sub renameObject {
    my ($object_ID, $new_display_name) = @_;
    my $object_info = getObjectInfo($object_ID);
    my $quoted_new_display_name = $new_display_name;
    $quoted_new_display_name =~ s/'/''/g;
    return qq(<font color='red'>ERROR: Object with this name already exists</font>)
    	if detectObjectCollision($object_info->{'TABLE_ID'}, $quoted_new_display_name);

    my $sql = qq(
    	update OBJECT 
    	set DISPLAY_NAME = '$quoted_new_display_name' 
    	where ID = '$object_ID'
    );

    $db->ExecuteSQL($sql);
    mydie("Unable to rename object class: " . $db->Error) if $db->Error;
    
    return qq(Object $object_info->{'DISPLAY_NAME'} renamed to $new_display_name.);
}

sub detectObjectCollision {
    my ($table_ID, $display_name) = @_;
    my $sql = qq(select ID from object where TABLE_ID = '$table_ID' AND DISPLAY_NAME = '$display_name');
    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to check for object collision: " . $db->Error) if $db->Error;
    return 1 if scalar(@rs);
    return 0;
}

sub displayDeleteObjConfirmation {
    my $object_ID = shift @_;
    my $object_info = getObjectInfo($object_ID);
    if (my $instance_count = getInstanceCount($object_ID, $object_info->{'TABLE_ID'})) {
    	return qq(There are $instance_count instances of $object_info->{'DISPLAY_NAME'}.  Please remap these to another object class before deleting.);
    }
    	
    return qq(
    	$object_info->{'DISPLAY_NAME'} has no instance data.  Please confirm delete or cancel.
    	<form action='$ENV{'SCRIPT_NAME'}'>
    		<input type='hidden' name='op' value='delete_object'>
    		<input type='hidden' name='object_ID' value='$object_ID'>
    		<input type='submit' value='DELETE'>&nbsp;&nbsp;<input type='button' value='Cancel' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=ontology"'>
    	</form>
    );
}

sub displayDeleteObjectAttributeConfirmationInterface {
    my $attribute_ID = shift @_;
    my $attribute_info = getAttributeInfo($attribute_ID);
    if (my $attribute_instance_count = getAttributeInstanceCount($attribute_ID, $attribute_info->{'ATTR_TABLE_ID'})) {
    	return qq(There are $attribute_instance_count instances of $attribute_info->{'display_name'}.  Please remap these to another attribute class before deleting.);
    }
    	
    return qq(
    	$attribute_info->{'display_name'} has no instance data.  Please confirm delete or cancel.
    	<form action='$ENV{'SCRIPT_NAME'}'>
    		<input type='hidden' name='op' value='delete_object_attribute'>
    		<input type='hidden' name='attribute_ID' value='$attribute_ID'>
    		<input type='submit' value='DELETE' >&nbsp;&nbsp;<input type='button' value='Cancel' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=ontology"'>
    	</form>
    );
}


sub displayUpdateObjectAttributeInterface {
    my $sql = qq(
      update ATTRIBUTE set
    	DISPLAY_NAME = '$attr_display_name',
    	ATTR_TABLE_ID = '$attr_table_ID',
    	DESCR = '$attribute_description',
    	DISPLAY_ORDER = '$attribute_display_order'
    	where
    	ID = '$attribute_ID';);
    	
    $db->ExecuteSQL($sql);
    mydie("Unable to update attribute info from the database: $sql" . $db->Error) if $db->Error;

    displayOntologyManager();
}


sub displayEditObjectAttributeInterface {
    my $attribute_ID = shift @_;
    my $attribute_info = getAttributeInfo($attribute_ID);
    my $table_schema = getTableSchema();

    return qq(
    	<form action='$ENV{'SCRIPT_NAME'}'>
    	<input type='hidden' name='op' value='update_object_attribute'>
    	<input type='hidden' name='attribute_ID' value='$attribute_ID'>
    	You are modifying the attributes for <b>$attribute_info->{'display_name'}</b> objects. 
    	<table>
    		<tr><td>Display Name</td><td><input type='text' name='attr_display_name' value='$attribute_info->{'display_name'}'></td></tr>
    		<tr>
    			<td>Attribute Type</td>
    			<td>
    				<select name='attr_table_ID'>
    					<option value='$table_schema->{'STR_ATTR_INST'}'>String</option>
    					<option value='$table_schema->{'DATE_ATTR_INST'}'>Date</option>
    					<option value='$table_schema->{'INT_ATTR_INST'}'>Integer</option>
    					<option value='$table_schema->{'DEC_ATTR_INST'}'>Decimal</option>
    					<option value='$table_schema->{'GEO_ATTR_INST'}'>Geospatial</option>
    					<option value='$table_schema->{'XML_ATTR_INST'}'>XML</option>
    					<option value='$table_schema->{'BIN_ATTR_INST'}'>Binary</option>
    				</select>
    			</td>
    		</tr>
    		<tr><td>Description</td><td><textarea name='attribute_description'>$attribute_info->{'description'}</textarea></td></tr>
    		<tr><td>Display Order</td><td><input type='text' name='attribute_display_order' size='4' value='0'></td></tr>
    	</table>
    	<input type='submit' value='Update Attribute' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=update_object_attribute"'>&nbsp;&nbsp;<input type='button' value='Cancel' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=ontology"'>
    	</form>
    );
}


sub displayNewObjNameInterface {
    my $object_ID = shift @_;
    my $object_info = getObjectInfo($object_ID);

    return qq(
    	<form action='$ENV{'SCRIPT_NAME'}'>
    		<input type='hidden' name='op' value='rename_object'>
    		<input type='hidden' name='object_ID' value='$object_ID'>
    		Please select a new name: 
    		<input type='text' name='new_object_name' value='$object_info->{'DISPLAY_NAME'}'>
    		<input type='submit' value='RENAME'>&nbsp;&nbsp;<input type='button' value='Cancel' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=ontology"'>
    	</form>
    );
}


sub getAttributeInfo {
    my $attribute_ID = shift @_;
    my $sql = qq(
    	select ID, PHYSICAL_NAME as physical_name, DISPLAY_NAME as display_name, DESCR as description, ATTR_TABLE_ID, CLASS_ID 
    	from ATTRIBUTE 
    	where ID = '$attribute_ID'
    );
    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to get object info from the database: " . $db->Error) if $db->Error;
    mydie("Invalid object_ID.") unless scalar @rs;
    return $rs[0];	
}


sub getObjectInfo {
    my $object_ID = shift @_;
    my $sql = qq(
    	select ID, PHYSICAL_NAME, DISPLAY_NAME, TABLE_ID, CLASS_ID 
    	from OBJECT 
    	where ID = '$object_ID'
    );
    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to get object info from the database: " . $db->Error) if $db->Error;
    mydie("Invalid object_ID.") unless scalar @rs;
    return $rs[0];	
}


sub getInstanceCount {
    my ($object_ID, $table_ID) = @_;
    my $table_schema = getTableSchema();
    my $sql = qq(
    	select count(*) as instance_count 
    	from $table_schema->{$table_ID} 
    	where OBJECT_ID = '$object_ID'
    );
    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to get instance count from the database: " . $db->Error) if $db->Error;
    return $rs[0]->{'instance_count'};
}


sub getAttributeInstanceCount {
    my ($attribute_ID, $attr_able_ID) = @_;
    my $table_schema = getTableSchema();
    my $sql = qq(
    	select count(*) as attribute_instance_count 
    	from $table_schema->{$attr_able_ID} 
    	where ATTR_ID = '$attribute_ID'
    );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to get instance count from the database: " . $db->Error) if $db->Error;

    return $rs[0]->{'attribute_instance_count'};
}


sub deleteObjectAttribute {
    my $attribute_ID = shift @_;
    my $sql = qq(
    	update ATTRIBUTE set DELETED_FLAG = 1 where ID = '$attribute_ID';
    );
    $db->ExecuteSQL($sql);
    mydie("Unable to delete object and attributes: " . $db->Error) if $db->Error;
}


sub deleteObject {
    my $object_ID = shift @_;
    my $sql = qq(
    	update OBJECT set DELETED_FLAG = 1 where ID = '$object_ID';
    	update ATTRIBUTE set DELETED_FLAG = 1 where OBJECT_ID = '$object_ID';
    );
    $db->ExecuteSQL($sql);
    mydie("Unable to delete object and attributes: " . $db->Error) if $db->Error;
}


sub displayNewAttrInterface {
    my $object_ID = shift @_;
    my $object_info = getObjectInfo($object_ID);
    my $table_schema = getTableSchema();

    return qq(
    	<form action='$ENV{'SCRIPT_NAME'}'>
    	<input type='hidden' name='op' value='create_attribute'>
    	<input type='hidden' name='object_ID' value='$object_ID'>
    	You are creating a new attribute for $object_info->{'DISPLAY_NAME'} objects. 
    	<table>
    		<tr><td>Display Name</td><td><input type='text' name='attr_display_name'></td></tr>
    		<tr>
    			<td>Attribute Type</td>
    			<td>
    				<select name='attr_table_ID'>
    					<option value='$table_schema->{'STR_ATTR_INST'}'>String</option>
    					<option value='$table_schema->{'DATE_ATTR_INST'}'>Date</option>
    					<option value='$table_schema->{'INT_ATTR_INST'}'>Integer</option>
    					<option value='$table_schema->{'DEC_ATTR_INST'}'>Decimal</option>
    					<option value='$table_schema->{'GEO_ATTR_INST'}'>Geospatial</option>
    					<option value='$table_schema->{'XML_ATTR_INST'}'>XML</option>
    					<option value='$table_schema->{'BIN_ATTR_INST'}'>Binary</option>
    				</select>
    			</td>
    		</tr>
    		<tr><td>Description</td><td><textarea name='attribute_descr'></textarea></td></tr>
    		<tr><td>Display Order</td><td><input type='text' name='display_order' size='4' value='0'></td></tr>
    	</table>
    	<input type='submit' value='Create Attribute'>&nbsp;&nbsp;<input type='button' value='Cancel' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=ontology"'>
    	</form>
    );
}

sub createAttribute {
    my ($object_ID, $attr_display_name, $attr_table_ID, $display_order, $attribute_descr) = @_;

    my $physical_name = $attr_display_name;
    $physical_name =~ s/\W/_/g;
    $display_name =~ s/'/''/g;

    return qq(<font color='red'>ERROR: An attribute with this name already exists for this object class.</font>)
    	if detectAttributeCollision($object_ID, $attr_display_name);
    
    my $sql = qq(
    	insert into ATTRIBUTE 
    	(ID, PHYSICAL_NAME, DISPLAY_NAME, ATTR_TABLE_ID, OBJECT_ID, DISPLAY_ORDER, DESCR, DELETED_FLAG, CLASS_ID)
    	VALUES (NEWID(), '$physical_name', '$attr_display_name', '$attr_table_ID', '$object_ID', $display_order, '$attribute_descr', 0, '$UNCLASSIFIED')
    );
    $db->ExecuteSQL($sql);
    mydie("Unable to create new attribute: " . $db->Error) if $db->Error;
    
    return qq(Attribute $attr_display_name successfully created.);
}

sub detectAttributeCollision {
    my ($object_ID, $attr_display_name) = @_;
    my $sql = qq(select ID from ATTRIBUTE where OBJECT_ID = '$object_ID' AND DISPLAY_NAME = '$attr_display_name');
    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to check for attribute collision: " . $db->Error) if $db->Error;
    return 1 if scalar(@rs);
    return 0;
}

######################################## xx DATA SOURCES SUBROUTINES ##########################

sub updateDateAttrInstTable {
    my ($dateValue, $dateAttrInst_ID) = @_;

    my $sql = qq(
    	update DATE_ATTR_INST 
    	set VALUE = '$dateValue'
    	where ID = '$dateAttrInst_ID'
    );

    $db->ExecuteSQL($sql);
    mydie("Unable to update date_attr_inst table: " . $db->Error) if $db->Error;
    
    return 1;
}


sub updateIntAttrInstTable {
    my ($intValue, $intAttrInst_ID) = @_;

    my $sql = qq(
    	update INT_ATTR_INST 
    	set VALUE = $intValue
    	where ID = '$intAttrInst_ID'
    );

    $db->ExecuteSQL($sql);
    mydie("Unable to update int_attr_inst table: " . $db->Error) if $db->Error;
    
    return 1;
}


sub updateStrAttrInstTable {
    my ($strValue, $strAttrInst_ID) = @_;

    my $sql = qq(
    	update STR_ATTR_INST 
    	set VALUE = '$strValue'
    	where ID = '$strAttrInst_ID'
    );

    $db->ExecuteSQL($sql);
    mydie("Unable to update str_attr_inst table: " . $db->Error) if $db->Error;
    
    return 1;
}


sub updateDataSources {

    my ( $data_sources_name, $dsNameAttrInst_ID, $data_sources_description, $dsDescriptionAttrInst_ID, $data_sources_gathering_mechanism, $dsGatheringMechanismAttrInst_ID, $data_sources_priority, $dsPriorityAttrInst_ID, $data_sources_URL, $dsURLAttrInst_ID, $data_sources_date_identified, $dsDate_IdentifiedAttrInst_ID) = @_;

    if (
    	  (updateStrAttrInstTable($data_sources_name, $dsNameAttrInst_ID)) && 
    	  (updateStrAttrInstTable($data_sources_description, $dsDescriptionAttrInst_ID)) && 
    	  (updateStrAttrInstTable($data_sources_gathering_mechanism, $dsGatheringMechanismAttrInst_ID)) && 
    	  (updateIntAttrInstTable($data_sources_priority, $dsPriorityAttrInst_ID)) && 
    		(updateStrAttrInstTable($data_sources_URL, $dsURLAttrInst_ID)) && 
    		(updateDateAttrInstTable($data_sources_date_identified, $dsDate_IdentifiedAttrInst_ID)) ) {
        return qq(Attribute instance tables updated);
    }
}


sub removeAssignEngineer {
	 my ($assignEngineerInst_ID, $dataSourceInst_ID) = @_;

   my $sql = qq(
     update LINK_INST set DELETED_FLAG = 1
		 where ENTITY_INST_ID1 = '$dataSourceInst_ID'
     and ENTITY_INST_ID2 = '$assignEngineerInst_ID';
   );
	 
	 # mydie($sql);
 
   my @rs = $db->ExecuteSQL($sql);
   mydie("Unable to remove assign engineer from database: " . $db->Error) if $db->Error;
    	
   return qq(Assigned engineer removed.);
}


sub displayConfirmRemoveAssignEngineerManager {
    my ($assignEngineerInst_ID, $dataSourceInst_ID) = @_;

      return qq(
    	Please confirm remove or cancel.
    	<form action='$ENV{'SCRIPT_NAME'}'>
    		<input type='hidden' name='op' value='remove_assign_engineer'>
    		<input type='hidden' name='assignEngineerInst_ID' value='$assignEngineerInst_ID'>
    		<input type='hidden' name='dataSourceInst_ID' value='$dataSourceInst_ID'>
    		<input type='submit' value='REMOVE' >&nbsp;&nbsp;<input type='button' value='Cancel' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=dataSources"'>
    	</form>
    );

}



sub displayUpdateDataSourcesManager {
    my ($entity_ID, $object_ID) = @_;

    my $dataSourceInfo = {};
    $dataSourceInfo = getDataSourceInfo($entity_ID, $object_ID);

		# my $assignedEngineerInfo = {};
		my @assignedEngineerInfo = getAssignedEngineerInfo($dataSourceInfo->{'dsName'}, 'Grok_User');

		my $dataSourceEntityInst_ID = getEntityInst_ID($dataSourceInfo->{'dsName'});

		my @freeAssignEngineerInfo = getFreeAssignEngineerInfo($dataSourceInfo->{'dsName'}, 'Grok_User');










    my $html = qq(
    	<a href='$ENV{'SCRIPT_NAME'}'>BACK</a> to GrokAdmin<br>
    	<h2>Data Sources Manager</h2>
    	<h3>Update Data Sources:</h3>

    	<form action='$ENV{'SCRIPT_NAME'}' method='get'>
    	<table>
    		<tr><td>Display name:</td><td><input type="text" name="data_sources_name" value='$dataSourceInfo->{'dsName'}'></td></tr>
    		<tr><td>Description</td><td><textarea name='data_sources_description'>$dataSourceInfo->{'dsDescription'}</textarea></td></tr>
    		<tr><td>Gathering Mechanism:</td><td><input type="text" name="data_sources_gathering_mechanism" value='$dataSourceInfo->{'dsGatheringMechanism'}'></td></tr>
    		<td>Priority:</td>
    			<td>
    		       <select name='data_sources_priority'>
    			       <option value='1'>1</option>
    			       <option value='2'>2</option>
    			       <option value='3'>3</option>
    			       <option value='4'>4</option>
    			       <option value='5'>5</option>
    		       </select>
    			</td>
    		<tr><td>Data Source URL:</td><td><input type="text" name="data_sources_URL" value='$dataSourceInfo->{'dsURL'}'></td></tr>
    		<tr><td>Date Identified:</td><td><input type="text" name="data_sources_date_identified" value='$dataSourceInfo->{'dsDate_Identified'}'></td></tr>
    <br>
    	<input type='hidden' name='op' value='update_data_source_attributes'>
    	<input type='hidden' name='object_ID' value='$object_ID'>
    	<input type='hidden' name='dsNameAttrInst_ID' value='$dataSourceInfo->{'dsNameAttrInst_ID'}'>
    	<input type='hidden' name='dsDescriptionAttrInst_ID' value='$dataSourceInfo->{'dsDescriptionAttrInst_ID'}'>
    	<input type='hidden' name='dsGatheringMechanismAttrInst_ID' value='$dataSourceInfo->{'dsGatheringMechanismAttrInst_ID'}'>
    	<input type='hidden' name='dsPriorityAttrInst_ID' value='$dataSourceInfo->{'dsPriorityAttrInst_ID'}'>
    	<input type='hidden' name='dsURLAttrInst_ID' value='$dataSourceInfo->{'dsURLAttrInst_ID'}'>
    	<input type='hidden' name='dsDate_IdentifiedAttrInst_ID' value='$dataSourceInfo->{'dsDate_IdentifiedAttrInst_ID'}'>
			
    		);

		if (scalar(@freeAssignEngineerInfo)>0) {
					$html .= qq(
    	        <td>Assign Engineer:</td>
			        <td>
              <select name="free_assign_engineer" id="Select1" size="4" multiple="multiple">
    		  );
          my $tabidx = 0;
          foreach $freeAssignEngineerInfo (@freeAssignEngineerInfo) {
          	$html .= qq(
                <option tabindex=$tabidx value='$freeAssignEngineerInfo->{'label'}'>$freeAssignEngineerInfo->{'label'}</option>
    			      );
    	      $tabidx++;
          }
		 }
		 else {
				$html .= qq(
    	    <td>Assign Engineer:  <b>None Available</b></td>
			    <td>
					);
		 }

		# need to pass up object_ID, data_sources_name, and list of free_assign_engineer
    $html .= qq(
    </select>
    	</td>
    	</table>
    <br>
    	<input type='submit' value='Update Data Source' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=update_data_source_attributes"'>&nbsp;&nbsp;<input type='button' value='Cancel' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=dataSources"'>
    	</form>
    	<hr>
    	<h3>Assigned Engineers:</h3>
    );


  	foreach $assignEngr (@assignedEngineerInfo) {
    		$row_html .= qq(<tr><td>$assignEngr->{'label'}
				(<a href='$ENV{'SCRIPT_NAME'}?op=confirm_remove_assign_engineer&assignEngineerInst_ID=$assignEngr->{'assignEngineerInst_ID'}&dataSourceInst_ID=$dataSourceEntityInst_ID'>remove</a>)</td><td align=middle></td></tr><br>
				);

## $row_html .= qq( <tr> <td>$assignEngr->{'label'}</td> <td><a href='$ENV{'SCRIPT_NAME'}?op=delete_assign_engineer></td> </tr> \n);

    }

		$html .= $row_html;
}

sub cleanBraces {
    my $oldBraces = shift @_;
    $oldBraces =~ s/{//g;
    $oldBraces =~ s/}//g;
    	return $oldBraces;
}

sub getAssignedEngineerInfo {
    my ( $dsName, $physical_name ) = @_;
    my $assignEngineer = {};

    my $sql = qq(  

			select e.label as label, e.id as assignEngineerInst_ID from ENTITY_INST as e, OBJECT as o
			where e.OBJECT_ID = o.ID
			and o.PHYSICAL_NAME = '$physical_name'
			and e.ID in ( select l.entity_inst_id2 from LINK_INST as l
			where  l.ENTITY_INST_ID1
			in ( select distinct ID from ENTITY_INST where LABEL = '$dsName')
			and l.DELETED_FLAG = 0);



    );

		# mydie($sql);

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to retrieve dataSources info from the database: " . $db->Error) if $db->Error;
    	
		# mydie( Dumper(\@rs) );
    
    foreach $row (@rs) {
    		my $entity_inst = {};
    		$entity_inst->{'label'} = $row->{'label'};
    		$entity_inst->{'assignEngineerInst_ID'} = cleanBraces($row->{'assignEngineerInst_ID'});
    		push @assignEngineer, $entity_inst;
    };

    return @assignEngineer;
}


sub getFreeAssignEngineerInfo {
    my ( $dsName, $physical_name ) = @_;
    my $freeAssignEngineer = {};

    my $sql = qq(  
        select e.label as label, e.id as freeAEInst_ID from ENTITY_INST as e, OBJECT as o
        where
        e.OBJECT_ID = o.ID
        and e.DELETED_FLAG = 0
        and o.PHYSICAL_NAME = 'Grok_User'
        and e.LABEL not in (
            select label as label from ENTITY_INST
			      where ID in ( select l.entity_inst_id2 from LINK_INST as l
			      where  l.deleted_flag = 0
		      	and l.ENTITY_INST_ID1
		      	in ( select distinct ID from ENTITY_INST where LABEL = '$dsName')));
    );

		# mydie("$sql");

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to retrieve dataSources info from the database: " . $db->Error) if $db->Error;
    	
		# mydie( Dumper(\@rs) );
    
    foreach $row (@rs) {
    		my $freeAssignEngineer = {};
    		$freeAssignEngineer->{'label'} = $row->{'label'};
    		$freeAssignEngineer->{'freeAEInst_ID'} = $row->{'freeAEInst_ID'};
    		push @freeAssignEngineer, $freeAssignEngineer;
    };

    return @freeAssignEngineer;
}


sub getDataSourceInfo {
    my ($entity_ID, $object_ID) = @_;

    my $dataSources = {};

    # get dataSource.Name info
    my $attribute_ID = getAttribute_ID('Data_Source', 'Name');
    my $attribute_info = getAttributeInfo($attribute_ID);
    my $attrInst_ID = getAttrInst_ID($entity_ID, $attribute_ID, $object_ID);
    my $dsName = getStrAttrInstValue($attrInst_ID);

 	$dataSources->{'dsName'} = $dsName;
 	$dataSources->{'dsNameAttrInst_ID'} = cleanBraces($attrInst_ID);


    # get dataSource.Description info
    my $attribute_ID = getAttribute_ID('Data_Source', 'Description');
    my $attribute_info = getAttributeInfo($attribute_ID);
    my $attrInst_ID = getAttrInst_ID($entity_ID, $attribute_ID, $object_ID);
    my $dsDescription = getStrAttrInstValue($attrInst_ID);

 	$dataSources->{'dsDescription'} = $dsDescription;
 	$dataSources->{'dsDescriptionAttrInst_ID'} = cleanBraces($attrInst_ID);


    # get dataSource.GatheringMechanism info
    my $attribute_ID = getAttribute_ID('Data_Source', 'Suggesting_Gathering_Mechanism');
    my $attribute_info = getAttributeInfo($attribute_ID);
    my $attrInst_ID = getAttrInst_ID($entity_ID, $attribute_ID, $object_ID);
    my $dsGatheringMechanism = getStrAttrInstValue($attrInst_ID);

 	$dataSources->{'dsGatheringMechanism'} = $dsGatheringMechanism;
 	$dataSources->{'dsGatheringMechanismAttrInst_ID'} = cleanBraces($attrInst_ID);


    # get dataSource.Priority info
    my $attribute_ID = getAttribute_ID('Data_Source', 'Priority');
    my $attribute_info = getAttributeInfo($attribute_ID);
    my $attrInst_ID = getAttrInst_ID($entity_ID, $attribute_ID, $object_ID);
    my $dsPriority = getIntAttrInstValue($attrInst_ID);

 	$dataSources->{'dsPriority'} = $dsPriority;
 	$dataSources->{'dsPriorityAttrInst_ID'} = cleanBraces($attrInst_ID);


    # get dataSource.URL info
    my $attribute_ID = getAttribute_ID('Data_Source', 'Source_URL');
    my $attribute_info = getAttributeInfo($attribute_ID);
    my $attrInst_ID = getAttrInst_ID($entity_ID, $attribute_ID, $object_ID);
    my $dsURL = getStrAttrInstValue($attrInst_ID);

 	$dataSources->{'dsURL'} = $dsURL;
 	$dataSources->{'dsURLAttrInst_ID'} = cleanBraces($attrInst_ID);


    # get dataSource.Date_Identified info
    my $attribute_ID = getAttribute_ID('Data_Source', 'Date_Identified');
    my $attribute_info = getAttributeInfo($attribute_ID);
    my $attrInst_ID = getAttrInst_ID($entity_ID, $attribute_ID, $object_ID);
    my $dsDate_Identified = getDateAttrInstValue($attrInst_ID);

 	$dataSources->{'dsDate_Identified'} = $dsDate_Identified;
 	$dataSources->{'dsDate_IdentifiedAttrInst_ID'} = cleanBraces($attrInst_ID);

    return $dataSources;
}


sub getAttrInst_ID {
    my ($entity_ID, $attribute_ID, $object_ID) = @_;

    my $sql = qq(
    	select ATTR_INST_ID as attrInst_ID
    	from OBJECT_ATTR_LINK_INST 
    	where 
    	  OBJECT_INST_ID = '$entity_ID'
    	and
    		ATTR_ID = '$attribute_ID'
    	and
    		OBJECT_ID = '$object_ID';
    );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to get oali id from the database: " . $db->Error) if $db->Error;

    return $attrInst_ID = $rs[0]->{'attrInst_ID'} if scalar(@rs);
    return 0;	
}


sub getDateAttrInstValue {
    my $attrInst_ID = shift @_;

    my $sql = qq(
    	select VALUE as dateValue
    	from DATE_ATTR_INST
    	where 
    	  ID = '$attrInst_ID';
    );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to get value from str_attr_inst table: " . $db->Error) if $db->Error;

    if ( scalar(@rs) ) {
        my $rsDate = $rs[0]->{'dateValue'};
        my ( $rsDatePart, $rsTimePart ) = split (/ /, $rsDate, 2);
        return $rsDatePart;
    }
    return 0;	
}


sub getIntAttrInstValue {
    my $attrInst_ID = shift @_;

    my $sql = qq(
    	select VALUE as intValue
    	from INT_ATTR_INST
    	where 
    	  ID = '$attrInst_ID';
    );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to get value from str_attr_inst table: " . $db->Error) if $db->Error;

    return $rs[0]->{'intValue'} if scalar(@rs);
    return 0;	
}


sub getStrAttrInstValue {
    my $attrInst_ID = shift @_;

    my $sql = qq(
    	select VALUE as strValue
    	from STR_ATTR_INST
    	where 
    	  ID = '$attrInst_ID';
    );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to get value from str_attr_inst table: " . $db->Error) if $db->Error;

    return $rs[0]->{'strValue'} if scalar(@rs);
    return 0;	
}


sub getEntityInfo {
    my $entity_ID = shift @_;
    my $sql = qq(
    	select ID, LABEL as label
    	from ENTITY_INST where ID = '$entity_ID';
    );
    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to get object info from the database: " . $db->Error) if $db->Error;
    mydie("Invalid object_ID.") unless scalar @rs;
    return $rs[0];	
}


sub deleteEntityInstance {
    	my $entity_ID = shift @_;

    	my @entityInfo = getEntityInfo($entity_ID);

      my $sql = qq(
        update ENTITY_INST set DELETED_FLAG = 1 where ID = '$entity_ID';
      );
 
      my @rs = $db->ExecuteSQL($sql);
      mydie("Unable to delete entity instance info from the database: " . $db->Error) if $db->Error;
    	
      return qq(Entity $entityInfo->{'label'} deleted.);
}


sub displayConfirmDeleteDataSourcesManager {
    my $entity_ID = shift @_;
    	
      return qq(
    	Please confirm delete or cancel.
    	<form action='$ENV{'SCRIPT_NAME'}'>
    		<input type='hidden' name='op' value='delete_entity_instance'>
    		<input type='hidden' name='entity_ID' value='$entity_ID'>
    		<input type='submit' value='DELETE' >&nbsp;&nbsp;<input type='button' value='Cancel' onclick='window.location="$ENV{'SCRIPT_NAME'}?op=dataSources"'>
    	</form>
    );
}


sub getObjectID {
      my $physical_name = shift @_;
      my $sql = qq(
        select distinct ID as object_ID from OBJECT 
        where PHYSICAL_NAME = '$physical_name';
      );
 
      my @rs = $db->ExecuteSQL($sql);
      mydie("Unable to retrieve dataSources info from the database: " . $db->Error) if $db->Error;
    	
      my $object_ID = "";
      foreach $row (@rs) {
    		  $object_ID = $row->{'object_ID'};
      };

      return $object_ID;
}

# CLEAN ENTITY INST TABLE
# delete from ENTITY_INST where id in (select e.Id as entity_ID from ENTITY_INST as e, OBJECT as o 
# where e.OBJECT_ID = o.ID and o.PHYSICAL_NAME = 'Data_Source');
#

#
# displayDataSourcesManager 
# 
sub displayDataSourcesManager {

    my $physical_name = shift @_;

    my $object_ID = getObjectID($physical_name);

    $object_ID =~ s/{//g;
    $object_ID =~ s/}//g;
    
    my @dataSources = getDataSources($physical_name);

    my @grokUsers = getGrokUsers('Grok_User');

    my $html = qq(
    	<a href='$ENV{'SCRIPT_NAME'}'>BACK</a> to GrokAdmin<br>
    	<h2>Data Sources Manager</h2>
    	<h3>Add New Data Sources:</h3>

    	<form action='$ENV{'SCRIPT_NAME'}' method='get'>
    	<table>
    		<tr><td>Display name:</td><td><input type="text" name="data_sources_name"></td></tr>
    		<tr><td>Description</td><td><textarea name='data_sources_description'></textarea></td></tr>
    		<tr><td>Gathering Mechanism:</td><td><input type="text" name="data_sources_gathering_mechanism"></td></tr>
    		<td>Priority:</td>
    			<td>
    		       <select name='data_sources_priority'>
    			       <option value='1'>1</option>
    			       <option value='2'>2</option>
    			       <option value='3'>3</option>
    			       <option value='4'>4</option>
    			       <option value='5'>5</option>
    		       </select>
    			</td>
    		<tr><td>Data Source URL:</td><td><input type="text" name="data_sources_URL"></td></tr>
    		<tr><td>Date Identified:</td><td><input type="text" name="data_sources_date_identified"></td></tr>

    		<td>Assign Engineer:</td>
    		<td>
      <select name="data_sources_assign_engineer" id="Select1" size="4" multiple="multiple">
    		);


    my $tabidx = 0;
    foreach $grokUser (@grokUsers) {
      $grokUser = cleanBraces($grokUser->{'label'});
    	$html .= qq(
          <option tabindex=$tabidx value='$grokUser'>$grokUser</option>
    			);
    	$tabidx++;
    }

    $html .= qq(
    </select>
    	</td>
    	</table>
    <br>
    	<input type='hidden' name='object_ID' value='$object_ID'>
    	<input type="hidden" name="op" value="add_data_sources">
    	<input type="submit" value="Add Data Sources to GROK">
   		<input type='button' value='Cancel' onclick='window.location="$ENV{'SCRIPT_NAME'}"'>
    	</form>
    	<hr>

    	<h3>Current Data Sources:</h3>
    	<table border=1>\n
    );

    foreach $dataSources (@dataSources) {
      $entity_ID = $dataSources->{'entity_ID'};
      $entity_ID =~ s/{//g;
      $entity_ID =~ s/}//g;
    	$html .= qq(
    	    <tr><td rowspan=1>$dataSources->{'label'} (
    			<a href='$ENV{'SCRIPT_NAME'}?op=update_data_sources&entity_ID=$entity_ID&object_ID=$object_ID'>edit</a> | 
    			<a href='$ENV{'SCRIPT_NAME'}?op=confirm_delete_data_sources&entity_ID=$entity_ID'>delete</a>)
    			</td></tr>);
    }

    $html .= qq(</table>\n);

    return $html;
}

#
# getDataSources 
# 1. this function retrieves all data sources from entity inst
#
sub getDataSources {
    my $physical_name = shift @_;
    	
    my $sql = qq(  
    	select e.ID as entity_ID, label as label  FROM ENTITY_INST as e, OBJECT as o
    	where e.OBJECT_ID = o.ID and o.PHYSICAL_NAME = '$physical_name' 
    		and e.DELETED_FLAG = 0
    		order by label;
    );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to retrieve dataSources info from the database: " . $db->Error) if $db->Error;
    	
    # mydie( Dumper(\@rs) );
    
    foreach $row (@rs) {
    		my $entity_inst = {};
    		$entity_inst->{'entity_ID'} = $row->{'entity_ID'};
    		$entity_inst->{'label'} = $row->{'label'};
    		push @dataSources, $entity_inst;
    };

    return @dataSources;
}


sub detectDateAttrInstCollision {
    my ($dateValue, $objectPhysicalName, $attributePhysicalName) =  @_;
    my $attribute_ID = getAttribute_ID($objectPhysicalName, $attributePhysicalName);

    my $sql = qq(
                select ID
    							from date_attr_inst as dateAttrInst_ID
    							where attr_id = '$attribute_ID'
                and value = '$dateValue';
            );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to check for date_attr_inst collision: " . $db->Error) if $db->Error;

    return $rs[0]->{'dateAttrInst_ID'} if scalar(@rs);
    return 0;
}

sub detectIntAttrInstCollision {
    my ($intValue, $objectPhysicalName, $attributePhysicalName) =  @_;
    my $attribute_ID = getAttribute_ID($objectPhysicalName, $attributePhysicalName);

    my $sql = qq(
                select DISTINCT ID as intAttrInst_ID
    							from int_attr_inst
    							where attr_id = '$attribute_ID'
                and value = '$intValue';
            );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to check for int_attr_inst collision: " . $db->Error) if $db->Error;

    return $rs[0]->{'intAttrInst_ID'} if scalar(@rs);
    return 0;
}


sub detectStrAttrInstCollision {
    my $value = shift @_;
    my $md5StrValue = md5_hex($value);

    my $sql = qq(
                select DISTINCT ID as strAttrInst_ID
    							from str_attr_inst
    							where md5 = '$md5StrValue'
                and value = '$value';
            );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to check for str_attr_inst collision: " . $db->Error) if $db->Error;

    return $rs[0]->{'strAttrInst_ID'} if scalar(@rs);
    return 0;
}


sub getSrcEntityInst_ID {
    my $label = shift @_;

    my $sql = qq(
    select distinct ID as srcEntityInst_ID
    from ENTITY_INST
    where label = '$label';
    );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to retrieve source entity inst ID from the database: " . $db->Error) if $db->Error;

    	my $srcEntityInst_ID = $rs[0]->{'srcEntityInst_ID'};

    return $srcEntityInst_ID;
}


sub getAttribute_ID {
    my ($objectPhysicalName, $attributePhysicalName) = @_;

    my $sql = qq(
    select distinct a.ID as attribute_ID
    from ATTRIBUTE as a, object as o 
    where a.object_id = o.id 
    and o.PHYSICAL_NAME = '$objectPhysicalName'
    and a.PHYSICAL_NAME = '$attributePhysicalName';
    );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to retrieve attribute ID from the database: " . $db->Error) if $db->Error;

    	my $attribute_ID = $rs[0]->{'attribute_ID'};

    $attribute_ID =~ s/{//g;
    $attribute_ID =~ s/}//g;

    return $attribute_ID;
}


sub addToIntAttrInstTable {
    	my ($intValue, $objectPhysicalName, $attributePhysicalName) =  @_;
    	my $attribute_ID = getAttribute_ID($objectPhysicalName, $attributePhysicalName);

      	my $sql = qq(
    	  INSERT INTO int_attr_inst
    	  (ID, ATTR_ID, VALUE) 
      	VALUES (NEWID(), '$attribute_ID', '$intValue') );

    $db->ExecuteSQL($sql);
    mydie("Unable to create new int_attr_inst entry: " . $db->Error) if $db->Error;
}


sub addToStrAttrInstTable {
    	my ($strValue, $objectPhysicalName, $attributePhysicalName) =  @_;
    	my $attribute_ID = getAttribute_ID($objectPhysicalName, $attributePhysicalName);

    	my $md5StrValue = md5_hex($strValue);
    	my $sha1StrValue = sha1_hex($strValue);


      	my $sql = qq(
    		INSERT INTO str_attr_inst
    		(ID, ATTR_ID, VALUE, MD5, SHA1) 
      		VALUES (NEWID(), '$attribute_ID', '$strValue', '$md5StrValue', '$sha1StrValue') );

    $db->ExecuteSQL($sql);
    mydie("Unable to create new str_attr_inst entry: " . $db->Error) if $db->Error;
}


sub addToDateAttrInstTable {
    	my ($dateValue, $objectPhysicalName, $attributePhysicalName) =  @_;
    	my $attribute_ID = getAttribute_ID($objectPhysicalName, $attributePhysicalName);

    	# TODO: FIGURE OUT WHAT THESE VALUES SHOULD BE
    my $posOffset = 1;
    	my $negOffest = 1;


      my $sql = qq(
        INSERT INTO DATE_ATTR_INST (
    	ID, ATTR_ID, VALUE, POS_OFFSET, NEG_OFFSET, LOCALE, 
    	CALENDAR_BASE, ISLAMIC_DATE, JEWISH_DATE, CHINESE_DATE) 
        VALUES ( NEWID(), '$attribute_ID', '$dateValue', 1, 1, NULL, 
        NULL, '$dateValue', '$dateValue', '$dateValue');

    );

    $db->ExecuteSQL($sql);
    mydie("Unable to create new date_attr_inst entry: " . $db->Error) if $db->Error;
}


sub addDataSourceElementsToAttrInstTables {

    my ($data_sources_name, $data_sources_description, $data_sources_gathering_mechanism, 
    		$data_sources_priority, $data_sources_URL, $data_sources_date_identified, $object_ID) = @_;


    my $oaliAttrInst_ID = '';
    # insert $data_source_name into str_attr_inst table
    if ( ($oaliattrInst_ID = detectStrAttrInstCollision ($data_sources_name, 'Data_Source', 'Name')) == 0 ) {
    		  addToStrAttrInstTable($data_sources_name, 'Data_Source', 'Name');
        $oaliAttrInst_ID = getStrAttributeInst_ID($data_sources_name, 'Data_Source', 'Name');
    }
    
    my $oaliObject_ID = $object_ID;
    my $oaliObjectInst_ID = getEntityInst_ID($data_sources_name);
    my $oaliAttr_ID = getAttribute_ID('Data_Source', 'Name');
    my $oaliSrcEntityInst_ID = getSrcEntityInst_ID('Software_GrokAdminTool');
 	my ($year, $month, $day) = Today();
 	my $oaliDateOfInformation = "$year-$month-$day";
    my $oaliConfidence = 1.0;
    my $oaliDerivedFlag = 1;
    my $oaliDeletedFlag = 1;
 	my $oaliClass_ID = $UNCLASSIFIED;

    addToOALITable( $oaliObjectInst_ID, $oaliAttrInst_ID, $oaliAttr_ID, $oaliSrcEntityInst_ID, $oaliDateOfInformation, $oaliConfidence, $oaliDerivedFlag, $oaliDeletedFlag, $oaliClass_ID, $oaliObject_ID );


    # insert $data_sources_description into str_attr_inst table
    if ( ($oaliAttrInst_ID = detectStrAttrInstCollision ($data_sources_description, 'Data_Source', 'Description')) == 0 ) {
    	  	addToStrAttrInstTable($data_sources_description, 'Data_Source', 'Description');
    	    $oaliAttrInst_ID = getStrAttributeInst_ID($data_sources_description, 'Data_Source', 'Description');
    }
    $oaliAttr_ID = getAttribute_ID('Data_Source', 'Description');
    	addToOALITable( $oaliObjectInst_ID, $oaliAttrInst_ID, $oaliAttr_ID, $oaliSrcEntityInst_ID, $oaliDateOfInformation, $oaliConfidence, $oaliDerivedFlag, $oaliDeletedFlag, $oaliClass_ID, $oaliObject_ID );


    # insert $data_sources_gathering_mechanism into str_attr_inst table
    if ( ($oaliAttrInst_ID = detectStrAttrInstCollision ($data_sources_gathering_mechanism, 'Data_Source', 'Suggesting_Gathering_Mechanism')) == 0 ) {
    	  	addToStrAttrInstTable($data_sources_gathering_mechanism, 'Data_Source', 'Suggesting_Gathering_Mechanism');
    	    $oaliAttrInst_ID = getStrAttributeInst_ID($data_sources_gathering_mechanism, 'Data_Source', 'Suggesting_Gathering_Mechanism');
    }
    $oaliAttr_ID = getAttribute_ID('Data_Source', 'Suggesting_Gathering_Mechanism');
    	addToOALITable( $oaliObjectInst_ID, $oaliAttrInst_ID, $oaliAttr_ID, $oaliSrcEntityInst_ID, $oaliDateOfInformation, $oaliConfidence, $oaliDerivedFlag, $oaliDeletedFlag, $oaliClass_ID, $oaliObject_ID );


    # insert $data_sources_priority into str_attr_inst table
    if ( ($oaliAttrInst_ID = detectIntAttrInstCollision ($data_sources_priority, 'Data_Source', 'Priority')) == 0 ) {
    		 addToIntAttrInstTable($data_sources_priority, 'Data_Source', 'Priority');
    	   $oaliAttrInst_ID = getIntAttributeInst_ID($data_sources_priority, 'Data_Source', 'Priority');
    }
    	$oaliAttr_ID = getAttribute_ID('Data_Source', 'Priority');
    	addToOALITable( $oaliObjectInst_ID, $oaliAttrInst_ID, $oaliAttr_ID, $oaliSrcEntityInst_ID, $oaliDateOfInformation, $oaliConfidence, $oaliDerivedFlag, $oaliDeletedFlag, $oaliClass_ID, $oaliObject_ID );


    # insert $data_sources_URL into str_attr_inst table
    if ( ($oaliAttrInst_ID = detectStrAttrInstCollision ($data_sources_URL, 'Data_Source', 'Source_URL')) == 0 ) {
    		 addToStrAttrInstTable($data_sources_URL, 'Data_Source', 'Source_URL');
    	   $oaliAttrInst_ID = getStrAttributeInst_ID($data_sources_URL, 'Data_Source', 'Source_URL');
    }
    	$oaliAttr_ID = getAttribute_ID('Data_Source', 'Source_URL');
    	addToOALITable( $oaliObjectInst_ID, $oaliAttrInst_ID, $oaliAttr_ID, $oaliSrcEntityInst_ID, $oaliDateOfInformation, $oaliConfidence, $oaliDerivedFlag, $oaliDeletedFlag, $oaliClass_ID, $oaliObject_ID );


    # TODO: ENSURE THE DATE IS IN THE YYYY-MM-DD FORMAT
    # insert $data_sources_date_identifiied into date_attr_inst table
    if ( ($oaliAttrInst_ID = detectDateAttrInstCollision ($data_sources_date_identified, 'Data_Source', 'Date_Identified')) == 0 ) {
    		  addToDateAttrInstTable($data_sources_date_identified, 'Data_Source', 'Date_Identified');
    	    $oaliAttrInst_ID = getDateAttributeInst_ID($data_sources_date_identified, 'Data_Source', 'Date_Identified');
    }
    	$oaliAttr_ID = getAttribute_ID('Data_Source', 'Date_Identified');
    	addToOALITable( $oaliObjectInst_ID, $oaliAttrInst_ID, $oaliAttr_ID, $oaliSrcEntityInst_ID, $oaliDateOfInformation, $oaliConfidence, $oaliDerivedFlag, $oaliDeletedFlag, $oaliClass_ID, $oaliObject_ID );

}

sub getDateAttributeInst_ID {
    	my ($strValue, $objectPhysicalName, $attributePhysicalName) =  @_;
    	my $attribute_ID = getAttribute_ID($objectPhysicalName, $attributePhysicalName);

      my $sql = qq(
    	  SELECT DISTINCT ID as dateAttributeInst_ID
    		FROM DATE_ATTR_INST
      WHERE ATTR_ID = '$attribute_ID'
    	  AND   VALUE =	'$strValue'
    	  ; );

      my @rs = $db->ExecuteSQL($sql);
      mydie("Unable to retrieve attribute instance id: " . $db->Error) if $db->Error;

      my $dateAttributeInst_ID = $rs[0]->{'dateAttributeInst_ID'};

      return $dateAttributeInst_ID;
}


sub getStrAttributeInst_ID {
    	my ($strValue, $objectPhysicalName, $attributePhysicalName) =  @_;
    	my $attribute_ID = getAttribute_ID($objectPhysicalName, $attributePhysicalName);

    	my $md5StrValue = md5_hex($strValue);
    	my $sha1StrValue = sha1_hex($strValue);


      my $sql = qq(
    	  SELECT DISTINCT ID as attributeInst_ID
    		FROM STR_ATTR_INST
      		WHERE ATTR_ID = '$attribute_ID'
    	  AND   VALUE =	'$strValue'
    		AND   MD5 =	'$md5StrValue'
    		AND   SHA1 =	'$sha1StrValue'; );

      my @rs = $db->ExecuteSQL($sql);
      mydie("Unable to retrieve attribute instance id: " . $db->Error) if $db->Error;

      my $strAttributeInst_ID = $rs[0]->{'attributeInst_ID'};
      $strAttributeInst_ID =~ s/{//g;
      $strAttributeInst_ID =~ s/}//g;
      return $strAttributeInst_ID;
}


sub getIntAttributeInst_ID {
    	my ($strValue, $objectPhysicalName, $attributePhysicalName) =  @_;
    	my $attribute_ID = getAttribute_ID($objectPhysicalName, $attributePhysicalName);


      my $sql = qq(
    	  SELECT DISTINCT ID as intAttributeInst_ID
    		FROM INT_ATTR_INST
      		WHERE ATTR_ID = '$attribute_ID'
    	  	AND   VALUE =	'$strValue'; 
    		);


      my @rs = $db->ExecuteSQL($sql);
      mydie("Unable to retrieve attribute instance id: " . $db->Error) if $db->Error;

      my $intAttributeInst_ID = $rs[0]->{'intAttributeInst_ID'};
      $intAttributeInst_ID =~ s/{//g;
      $intAttributeInst_ID =~ s/}//g;

      return $intAttributeInst_ID;
}


sub getEntityInst_ID {
    my $label = shift @_;
    my $sql = qq(
                select distinct E.ID as entityInst_ID
    							from entity_inst as e, object as o 
    							where e.OBJECT_ID = o.ID 
    							and o.PHYSICAL_NAME = 'Data_Source'
    							and e.label = '$label';
            );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to retrieve entity instance id " . $db->Error) if $db->Error;

    my $entityInst_ID = $rs[0]->{'entityInst_ID'};
    $entityInst_ID =~ s/{//g;
    $entityInst_ID =~ s/}//g;
    return $entityInst_ID;
}


sub createEntityInst {
    my ($data_sources_name, $data_sources_description, $data_sources_gathering_mechanism, $data_sources_priority, $data_sources_URL, $data_sources_date_identified, $object_ID) = @_;

    # 1. create an entity instance record
    # 2. create entries in the appropriate attr_inst table
    # 3. link the object and attributes and attr_inst together in the OALI
    #

    $object_ID =~ s/{//g;
    $object_ID =~ s/}//g;

    return qq(<font color='red'>ENTITY INSTANCE CREATION ERROR: Entity with the name $data_sources_name already exists</font>)
       if detectEntityInstanceCollision($data_sources_name, 'Data_Source');
    
    my $sql = qq(
    	INSERT INTO entity_inst 
    	(ID, OBJECT_ID, LABEL, DELETED_FLAG, CLASS_ID)
    	VALUES (NEWID(), '$object_ID', '$data_sources_name', 0, '$UNCLASSIFIED')
    );

    $db->ExecuteSQL($sql);
    mydie("Unable to create new entity instance entry: " . $db->Error) if $db->Error;
    

    addDataSourceElementsToAttrInstTables ($data_sources_name, $data_sources_description, $data_sources_gathering_mechanism, $data_sources_priority, $data_sources_URL, $data_sources_date_identified, $object_ID);


        return qq(Object $data_sources_name successfully created.);
}


sub linkDataSourceToAssignEngineers {
    	my ($object_ID, $data_sources_name, @data_sources_assign_engineer) = @_;

    	# 1. get entityInst_ID for data_source
      my $dataSourceEntityInst_ID = getEntityInst_ID($data_sources_name);
    	
    	my $retVal = 0;
    	# 2. get entityInst_ID for each assigned engineer (grokUser) and link up
      foreach $dsAssignEngineer (@data_sources_assign_engineer) {
    			my $dsAssignEngineerEntityInst_ID = getGrokUserEntityInst_ID($dsAssignEngineer);
    			$retVal += linkUpEntities($object_ID, $dataSourceEntityInst_ID, $dsAssignEngineerEntityInst_ID);
    	}

    	if ($retVal) {
    					return qq(Problems linking up data source to engineer);
    	}
    	return "";
}


sub linkUpEntities {
    my ($object_ID, $dataSourceEntityInst_ID, $dsAssignEngineerEntityInst_ID) = @_;

    my $sql = qq(
    	INSERT INTO link_inst 
    	(ID, OBJECT_ID, ENTITY_INST_ID1, ENTITY_INST_ID2, DIRECTION, DELETED_FLAG, CLASS_ID)
    	VALUES (NEWID(), '$object_ID', '$dataSourceEntityInst_ID', '$dsAssignEngineerEntityInst_ID', 0, 0, '$UNCLASSIFIED')
    );


    $db->ExecuteSQL($sql);
    mydie("Unable to create link instance: " . $db->Error) if $db->Error;

		return 0;
}


sub removeLinkInstance {
    my ($object_ID, $dataSourceEntityInst_ID, $dsAssignEngineerEntityInst_ID) = @_;

    my $sql = qq(
    	UPDATE link_inst 
			SET deleted_flag = 1
			WHERE
			entity_inst_id1 = '$dataSourceEntityInst_ID'
			AND
			entity_inst_id2 = '$dsAssignEngineerEntityInst_ID';	
    );

    $db->ExecuteSQL($sql);
    mydie("Unable to remove link instance: " . $db->Error) if $db->Error;

		return 0;
}


sub detectEntityInstanceCollision {
    my ($label, $physical_name) = @_;
    my $sql = qq(
                select E.ID 
    			from entity_inst as e, object as o 
    			where e.OBJECT_ID = o.ID 
    			and o.PHYSICAL_NAME = '$physical_name'
    			and e.label = '$label';
            );

    my @rs = $db->ExecuteSQL($sql);
    mydie("Unable to check for object collision: " . $db->Error) if $db->Error;

    return 1 if scalar(@rs);
    return 0;
}


######################################## xo OALI SUBROUTINES ########################################
sub addToOALITable {
    my ( $oaliObjectInst_ID, $oaliAttrInst_ID, $oaliAttr_ID, $oaliSrcEntityInst_ID, $oaliDateOfInformation, $oaliConfidence, $oaliDerivedFlag, $oaliDeletedFlag, $oaliClass_ID, $oaliObject_id ) = @_;

    my $sql = qq( INSERT INTO OBJECT_ATTR_LINK_INST ( 
    	    ID, 
    			OBJECT_INST_ID, 
    			ATTR_INST_ID, 
    			OBJECT_ID, 
    			ATTR_ID, 
    			SRC_ENTITY_INST_ID, 
    			DATE_OF_INFORMATION, 
    			CONFIDENCE, 
    			DERIVED_FLAG, 
    			DELETED_FLAG, 
    			CLASS_ID 
    			)
        VALUES ( 
    			NEWID(), 
    			'$oaliObjectInst_ID', 
    			'$oaliAttrInst_ID', 
    			'$oaliObject_id' ,
    			'$oaliAttr_ID', 
    			'$oaliSrcEntityInst_ID', 
    			'$oaliDateOfInformation', 
    			'$oaliConfidence', 
    			'$oaliDerivedFlag', 
    			'$oaliDeletedFlag', 
    			'$oaliClass_ID' 
    			); );

    $db->ExecuteSQL($sql);
    mydie("Unable to create object_attr_link entry: " . $db->Error) if $db->Error;
}


######################################## DATA CLASSIFICATION SUBROUTINES ##########################
sub displayDataClassificationManager {

    my $html;
    $html=qq(<h1>DATA CLASSIFICATION MANAGER GOES HERE</h1>);
    return $html;
}



######################################## TRANSLITERATE REGULAR EXPRESSIONS SUBROUTINES ##############
sub displayTransliterateREManager {

    my $html;
    $html=qq(<h1>TRANSLITERATE REGULAR EXPRESSIONS MANAGER GOES HERE</h1>);
    return $html;
}



######################################## EDIT LANGUAGES SUBROUTINES #################################
sub displayLanguageManager {

    my $html;
    $html=qq(<h1>EDIT LANGUAGES MANAGER GOES HERE</h1>);
    return $html;
}



######################################## IMPORT EXPORT SUBROUTINES ###################################
sub displayImportExportInterface {

    my $html;
    $html=qq(<h1>IMPORT EXPORT MANAGER GOES HERE</h1>);
    return $html;
}
