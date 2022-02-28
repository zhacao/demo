Configuration DSCTest1
{
    Import-DscResource -ModuleName 'nx'

    Node IsPresent
    {
        nxPackage python3
        {
            Name              = 'python3'
            Ensure            = 'Present'
            PackageManager    = 'Apt'
        }
    }

    Node IsNotPresent
    {
        nxPackage python3
        {
            Name              = 'python3'
            Ensure            = 'Absent'
        }
    }
}