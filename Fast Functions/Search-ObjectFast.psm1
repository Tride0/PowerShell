Function Search-ObjectFast {
    # This function is similiar to Where-Object but cannot use a scriptblock (filterscript) to filter objects.
    Param(
        [Ref]$Data,
        $Property,
        $Value
    )
    $Source = '
    using System;
    using System.Management.Automation;
    using System.Collections.Generic;
 
    namespace FastSearch
    {
 
        public static class Search
        {
            public static List<Object> Find(PSObject[] collection, string column, string data)
            {
                List<Object> results = new List<Object>();
                foreach(PSObject item in collection)
                {
                    if (item.Properties[column].Value.ToString() == data) { results.Add(item); }
                }
 
                return results;
            }
        }
    }
    '
    Try {
        Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp -ErrorAction SilentlyContinue
    }
    Catch {}
    Return [FastSearch.Search]::Find($Data.Value, $Property, $Value)
}
