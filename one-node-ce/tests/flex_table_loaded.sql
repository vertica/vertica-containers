-- Copyright (c) [2021-2023] OpenText.

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--    http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


-- The test in isinstalled.sql uses "= N" instead of "> 0", because
-- that file  knows how many functions are in the library (N).
-- We don't (it might change on us), but as long as there are some
-- functions loaded, we can be happy.
select (count(0) > 0)
from user_libraries 
inner join user_library_manifest 
        on user_libraries.lib_name = user_library_manifest.lib_name 
        where user_library_manifest.lib_name = 'FlexTableLib' 
            and (user_libraries.md5_sum = '__MD5__' 
                 or public.length('__MD5__') = 7);
