-- remove Campcaster related preferences
DELETE FROM `SystemPreferences` WHERE `varname` ='UseCampcasterAudioclips';
DELETE FROM `SystemPreferences` WHERE `varname` ='CampcasterHostName';
DELETE FROM `SystemPreferences` WHERE `varname` ='CampcasterHostPort';
DELETE FROM `SystemPreferences` WHERE `varname` ='CampcasterXRPCPath';
DELETE FROM `SystemPreferences` WHERE `varname` ='CampcasterXRPCFile';

-- Fix references to duplicated widgets
UPDATE `WidgetContext_Widget`
SET fk_widget_id = (
    SELECT w1.id FROM `Widget` w1, `Widget` w2 WHERE w1.class = w2.class AND w1.id > w2.id AND w2.id = fk_widget_id
)
WHERE fk_widget_id IN (
    SELECT w2.id FROM `Widget` w1, `Widget` w2 WHERE w1.class = w2.class AND w1.id > w2.id
);

-- Delete duplicated widgets
DELETE FROM `Widget`
WHERE ID IN (
    -- Must be materialized not to fail
    SELECT ID FROM (
        SELECT w2.id FROM `Widget` w1, `Widget` w2 WHERE w1.class = w2.class AND w1.id > w2.id
    ) as tmp
);

-- Change Widget absolute paths to relative
UPDATE `Widget`
SET path = SUBSTRING(path, LOCATE('extensions', path) + LENGTH('extensions') + 1)
WHERE path LIKE '/%' OR path LIKE '_:\\\\%';

-- Delete missing Widget references
DELETE FROM `WidgetContext_Widget`
WHERE fk_widget_id NOT IN (
    SELECT id FROM `Widget`
);

-- change javascript directory references with the js for MapMarkerDirectory preference
-- only if the default is used otherwise the preference should be kept
UPDATE `SystemPreferences` SET `value` = '/js/geocoding/markers/' WHERE `varname` = 'MapMarkerDirectory' AND `value` = '/javascript/geocoding/markers/';

-- Remove the sync phorum user from sql 
DELETE FROM `liveuser_grouprights` WHERE `right_id` IN (SELECT `right_id` FROM `liveuser_rights` WHERE `right_define_name` = 'SyncPhorumUsers');
DELETE FROM `liveuser_userrights` WHERE `right_id` IN (SELECT `right_id` FROM `liveuser_rights` WHERE `right_define_name` = 'SyncPhorumUsers');
DELETE FROM `liveuser_rights` WHERE `right_define_name` = 'SyncPhorumUsers';

system php ./acl.php
system php ./transfer_phorum.php
system php ./javascript_js_cleanup.php
