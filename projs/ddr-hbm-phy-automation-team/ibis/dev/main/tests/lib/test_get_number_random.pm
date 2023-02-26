###############################################################################
# Testcases for get_number test.
#
# Author: Harsimrat Singh Wadhawan
###############################################################################
package test_get_number_random;

use strict;
use warnings;
use FindBin;

use Exporter;

use lib "$FindBin::Bin/../../lib/perl";
use Util::CommonHeader;

our @ISA = qw(Exporter);

# Symbols (subs or vars) to export by default
our @EXPORT = qw(
  %RANDOM_VECTOR @POSITIVE_VECTOR @NEGATIVE_VECTOR
);

# Symbols to export by request
our @EXPORT_OK = qw();

our %RANDOM_VECTOR = (
    '127' => {
        'insert' => '622.000mV ',
        'expect' => '0.622'
    },
    '32' => {
        'insert' => '1.891pF ',
        'expect' => '1.891e-012'
    },
    '90' => {
        'insert' => '1.357pF ',
        'expect' => '1.357e-012'
    },
    '206' => {
        'insert' => '549.000mV ',
        'expect' => '0.549'
    },
    '118' => {
        'insert' => '566.000mV ',
        'expect' => '0.566'
    },
    '71' => {
        'insert' => '353.000ps ',
        'expect' => '3.53e-010'
    },
    '102' => {
        'insert' => '1.332pF ',
        'expect' => '1.332e-012'
    },
    '16' => {
        'insert' => '1.330pF ',
        'expect' => '1.33e-012'
    },
    '55' => {
        'insert' => '408.000ps ',
        'expect' => '4.08e-010'
    },
    '84' => {
        'insert' => '469.049fF ',
        'expect' => '4.69049e-013'
    },
    '233' => {
        'insert' => '715.000mV ',
        'expect' => '0.715'
    },
    '259' => {
        'insert' => '1.165V ',
        'expect' => '1.165 '
    },
    '194' => {
        'insert' => '483.554nA ',
        'expect' => '4.83554e-007'
    },
    '57' => {
        'insert' => '119.000ps ',
        'expect' => '1.19e-010'
    },
    '220' => {
        'insert' => '14.070mA ',
        'expect' => '0.01407'
    },
    '163' => {
        'insert' => '2.042pF ',
        'expect' => '2.042e-012'
    },
    '89' => {
        'insert' => '65.000ps ',
        'expect' => '6.5e-011'
    },
    '175' => {
        'insert' => '1.099V ',
        'expect' => '1.099 '
    },
    '31' => {
        'insert' => '174.000ps ',
        'expect' => '1.74e-010'
    },
    '35' => {
        'insert' => '-1.090V ',
        'expect' => '-1.090 '
    },
    '11' => {
        'insert' => '347.000ps ',
        'expect' => '3.47e-010'
    },
    '208' => {
        'insert' => '734.000mV ',
        'expect' => '0.734'
    },
    '93' => {
        'insert' => '802.000ps ',
        'expect' => '8.02e-010'
    },
    '29' => {
        'insert' => '872.000ps ',
        'expect' => '8.72e-010'
    },
    '199' => {
        'insert' => '1.257V ',
        'expect' => '1.257 '
    },
    '114' => {
        'insert' => '1.313pF ',
        'expect' => '1.313e-012'
    },
    '226' => {
        'insert' => '5.664mA ',
        'expect' => '0.005664'
    },
    '58' => {
        'insert' => '121.000ps ',
        'expect' => '1.21e-010'
    },
    '211' => {
        'insert' => '588.000mV ',
        'expect' => '0.588'
    },
    '153' => {
        'insert' => '10.740mA ',
        'expect' => '0.01074'
    },
    '15' => {
        'insert' => '1.896pF ',
        'expect' => '1.896e-012'
    },
    '101' => {
        'insert' => '1.196V ',
        'expect' => '1.196 '
    },
    '73' => {
        'insert' => '385.000ps ',
        'expect' => '3.85e-010'
    },
    '76' => {
        'insert' => '1.906pF ',
        'expect' => '1.906e-012'
    },
    '62' => {
        'insert' => '642.000ps ',
        'expect' => '6.42e-010'
    },
    '67' => {
        'insert' => '474.000ps ',
        'expect' => '4.74e-010'
    },
    '241' => {
        'insert' => '-65.948mA ',
        'expect' => '-0.065948'
    },
    '198' => {
        'insert' => '7.720mA ',
        'expect' => '0.00772'
    },
    '139' => {
        'insert' => '84.810uA ',
        'expect' => '8.481e-005'
    },
    '129' => {
        'insert' => '69.720uA ',
        'expect' => '6.972e-005'
    },
    '273' => {
        'insert' => '704.000mV ',
        'expect' => '0.704'
    },
    '236' => {
        'insert' => '232.100uV ',
        'expect' => '0.0002321'
    },
    '249' => {
        'insert' => '87.990mA ',
        'expect' => '0.08799'
    },
    '218' => {
        'insert' => '447.000mV ',
        'expect' => '0.447'
    },
    '202' => {
        'insert' => '101.200uA ',
        'expect' => '0.0001012'
    },
    '168' => {
        'insert' => '4.464mA ',
        'expect' => '0.004464'
    },
    '184' => {
        'insert' => '313.500uA ',
        'expect' => '0.0003135'
    },
    '135' => {
        'insert' => '1.901mA ',
        'expect' => '0.001901'
    },
    '14' => {
        'insert' => '713.000ps ',
        'expect' => '7.13e-010'
    },
    '145' => {
        'insert' => '1.929nA ',
        'expect' => '1.929e-009'
    },
    '49' => {
        'insert' => '2.049pF ',
        'expect' => '2.049e-012'
    },
    '178' => {
        'insert' => '2.021pF ',
        'expect' => '2.021e-012'
    },
    '24' => {
        'insert' => '783.220fF ',
        'expect' => '7.8322e-013'
    },
    '140' => {
        'insert' => '11.630mA ',
        'expect' => '0.01163'
    },
    '124' => {
        'insert' => '343.000mV ',
        'expect' => '0.343'
    },
    '104' => {
        'insert' => '2.097mA ',
        'expect' => '0.002097'
    },
    '131' => {
        'insert' => '1.983pF ',
        'expect' => '1.983e-012'
    },
    '181' => {
        'insert' => '8.214uA ',
        'expect' => '8.214e-006'
    },
    '234' => {
        'insert' => '287.000mV ',
        'expect' => '0.287'
    },
    '154' => {
        'insert' => '676.000mV ',
        'expect' => '0.676'
    },
    '0' => {
        'insert' => '305.000ps ',
        'expect' => '3.05e-010'
    },
    '23' => {
        'insert' => '118.000ps ',
        'expect' => '1.18e-010'
    },
    '96' => {
        'insert' => '490.000mV ',
        'expect' => '0.49'
    },
    '159' => {
        'insert' => '-36.000mA ',
        'expect' => '-0.036'
    },
    '160' => {
        'insert' => '12.290mA ',
        'expect' => '0.01229'
    },
    '47' => {
        'insert' => '1.200V ',
        'expect' => '1.200 '
    },
    '8' => {
        'insert' => '175.000ps ',
        'expect' => '1.75e-010'
    },
    '98' => {
        'insert' => '33.750uA ',
        'expect' => '3.375e-005'
    },
    '37' => {
        'insert' => '60.000ps ',
        'expect' => '6e-011'
    },
    '43' => {
        'insert' => '97.000ps ',
        'expect' => '9.7e-011'
    },
    '270' => {
        'insert' => '1.164V ',
        'expect' => '1.164 '
    },
    '195' => {
        'insert' => '1.318pF ',
        'expect' => '1.318e-012'
    },
    '5' => {
        'insert' => '653.883fF ',
        'expect' => '6.53883e-013'
    },
    '21' => {
        'insert' => '175.000ps ',
        'expect' => '1.75e-010'
    },
    '193' => {
        'insert' => '474.000mV ',
        'expect' => '0.474'
    },
    '119' => {
        'insert' => '811.300uA ',
        'expect' => '0.0008113'
    },
    '180' => {
        'insert' => '549.000mV ',
        'expect' => '0.549'
    },
    '244' => {
        'insert' => '459.100uA ',
        'expect' => '0.0004591'
    },
    '162' => {
        'insert' => '2.039pF ',
        'expect' => '2.039e-012'
    },
    '246' => {
        'insert' => '274.700uV ',
        'expect' => '0.0002747'
    },
    '240' => {
        'insert' => '-24.122mA ',
        'expect' => '-0.024122'
    },
    '74' => {
        'insert' => '14.000ps ',
        'expect' => '1.4e-011'
    },
    '61' => {
        'insert' => '2.360V ',
        'expect' => '2.360 '
    },
    '230' => {
        'insert' => '12.380mA ',
        'expect' => '0.01238'
    },
    '115' => {
        'insert' => '2.042pF ',
        'expect' => '2.042e-012'
    },
    '103' => {
        'insert' => '649.175fF ',
        'expect' => '6.49175e-013'
    },
    '201' => {
        'insert' => '710.000mV ',
        'expect' => '0.71'
    },
    '113' => {
        'insert' => '1.840pF ',
        'expect' => '1.84e-012'
    },
    '152' => {
        'insert' => '-103.996mA ',
        'expect' => '-0.103996'
    },
    '189' => {
        'insert' => '1.098V ',
        'expect' => '1.098 '
    },
    '266' => {
        'insert' => '177.800uA ',
        'expect' => '0.0001778'
    },
    '91' => {
        'insert' => '290.000ps ',
        'expect' => '2.9e-010'
    },
    '107' => {
        'insert' => '10.850mA ',
        'expect' => '0.01085'
    },
    '87' => {
        'insert' => '867.000ps ',
        'expect' => '8.67e-010'
    },
    '174' => {
        'insert' => '1.822pF ',
        'expect' => '1.822e-012'
    },
    '77' => {
        'insert' => '216.000ps ',
        'expect' => '2.16e-010'
    },
    '214' => {
        'insert' => '1.223V ',
        'expect' => '1.223 '
    },
    '221' => {
        'insert' => '76.070uA ',
        'expect' => '7.607e-005'
    },
    '39' => {
        'insert' => '64.000ps ',
        'expect' => '6.4e-011'
    },
    '64' => {
        'insert' => '2.042pF ',
        'expect' => '2.042e-012'
    },
    '97' => {
        'insert' => '1.321pF ',
        'expect' => '1.321e-012'
    },
    '12' => {
        'insert' => '205.000ps ',
        'expect' => '2.05e-010'
    },
    '41' => {
        'insert' => '170.000ps ',
        'expect' => '1.7e-010'
    },
    '52' => {
        'insert' => '-630.000mV ',
        'expect' => '-0.63'
    },
    '229' => {
        'insert' => '78.690uA ',
        'expect' => '7.869e-005'
    },
    '45' => {
        'insert' => '410.000ps ',
        'expect' => '4.1e-010'
    },
    '260' => {
        'insert' => '12.000uA ',
        'expect' => '1.2e-005'
    },
    '237' => {
        'insert' => '113.000mV ',
        'expect' => '0.113'
    },
    '188' => {
        'insert' => '1.287pF ',
        'expect' => '1.287e-012'
    },
    '68' => {
        'insert' => '894.000ps ',
        'expect' => '8.94e-010'
    },
    '1' => {
        'insert' => '265.000ps ',
        'expect' => '2.65e-010'
    },
    '136' => {
        'insert' => '7.190mA ',
        'expect' => '0.00719'
    },
    '116' => {
        'insert' => '9.230mA ',
        'expect' => '0.00923'
    },
    '144' => {
        'insert' => '261.000mV ',
        'expect' => '0.261'
    },
    '100' => {
        'insert' => '8.640mA ',
        'expect' => '0.00864'
    },
    '222' => {
        'insert' => '275.200uV ',
        'expect' => '0.0002752'
    },
    '25' => {
        'insert' => '544.000ps ',
        'expect' => '5.44e-010'
    },
    '120' => {
        'insert' => '11.640mA ',
        'expect' => '0.01164'
    },
    '83' => {
        'insert' => '865.000ps ',
        'expect' => '8.65e-010'
    },
    '254' => {
        'insert' => '150.500uA ',
        'expect' => '0.0001505'
    },
    '177' => {
        'insert' => '3.146uA ',
        'expect' => '3.146e-006'
    },
    '217' => {
        'insert' => '119.968nA ',
        'expect' => '1.19968e-007'
    },
    '239' => {
        'insert' => '8.500mA ',
        'expect' => '0.0085'
    },
    '122' => {
        'insert' => '633.364fF ',
        'expect' => '6.33364e-013'
    },
    '143' => {
        'insert' => '802.000mV ',
        'expect' => '0.802'
    },
    '269' => {
        'insert' => '141.000mV ',
        'expect' => '0.141'
    },
    '205' => {
        'insert' => '494.000mV ',
        'expect' => '0.494'
    },
    '158' => {
        'insert' => '1.308pF ',
        'expect' => '1.308e-012'
    },
    '42' => {
        'insert' => '533.000ps ',
        'expect' => '5.33e-010'
    },
    '22' => {
        'insert' => '430.000ps ',
        'expect' => '4.3e-010'
    },
    '46' => {
        'insert' => '39.000ps ',
        'expect' => '3.9e-011'
    },
    '235' => {
        'insert' => '5.881nA ',
        'expect' => '5.881e-009'
    },
    '6' => {
        'insert' => '19.000ps ',
        'expect' => '1.9e-011'
    },
    '36' => {
        'insert' => '80.000ps ',
        'expect' => '8e-011'
    },
    '213' => {
        'insert' => '12.390mA ',
        'expect' => '0.01239'
    },
    '183' => {
        'insert' => '108.400uA ',
        'expect' => '0.0001084'
    },
    '94' => {
        'insert' => '297.000ps ',
        'expect' => '2.97e-010'
    },
    '51' => {
        'insert' => '36.000ps ',
        'expect' => '3.6e-011'
    },
    '265' => {
        'insert' => '61.290uA ',
        'expect' => '6.129e-005'
    },
    '169' => {
        'insert' => '168.000uA ',
        'expect' => '0.000168'
    },
    '132' => {
        'insert' => '331.400uV ',
        'expect' => '0.0003314'
    },
    '171' => {
        'insert' => '202.400uV ',
        'expect' => '0.0002024'
    },
    '200' => {
        'insert' => '1.445mA ',
        'expect' => '0.001445'
    },
    '18' => {
        'insert' => '23.000ps ',
        'expect' => '2.3e-011'
    },
    '125' => {
        'insert' => '377.606nA ',
        'expect' => '3.77606e-007'
    },
    '44' => {
        'insert' => '342.000ps ',
        'expect' => '3.42e-010'
    },
    '27' => {
        'insert' => '840.000mV ',
        'expect' => '0.84'
    },
    '272' => {
        'insert' => '1.166V ',
        'expect' => '1.166 '
    },
    '161' => {
        'insert' => '1.851pF ',
        'expect' => '1.851e-012'
    },
    '190' => {
        'insert' => '14.640uA ',
        'expect' => '1.464e-005'
    },
    '95' => {
        'insert' => '188.000ps ',
        'expect' => '1.88e-010'
    },
    '20' => {
        'insert' => '426.000ps ',
        'expect' => '4.26e-010'
    },
    '109' => {
        'insert' => '478.000mV ',
        'expect' => '0.478'
    },
    '231' => {
        'insert' => '6.032mV ',
        'expect' => '0.006032'
    },
    '243' => {
        'insert' => '751.000mV ',
        'expect' => '0.751'
    },
    '151' => {
        'insert' => '-25.820mA ',
        'expect' => '-0.02582'
    },
    '148' => {
        'insert' => '62.100mV ',
        'expect' => '0.0621'
    },
    '78' => {
        'insert' => '603.000ps ',
        'expect' => '6.03e-010'
    },
    '106' => {
        'insert' => '106.000uA ',
        'expect' => '0.000106'
    },
    '275' => {
        'insert' => '104.954nA ',
        'expect' => '1.04954e-007'
    },
    '157' => {
        'insert' => '363.700uV ',
        'expect' => '0.0003637'
    },
    '65' => {
        'insert' => '2.044pF ',
        'expect' => '2.044e-012'
    },
    '197' => {
        'insert' => '1.260V ',
        'expect' => '1.260 '
    },
    '203' => {
        'insert' => '11.360mA ',
        'expect' => '0.01136'
    },
    '261' => {
        'insert' => '477.470nA ',
        'expect' => '4.7747e-007'
    },
    '138' => {
        'insert' => '699.000mV ',
        'expect' => '0.699'
    },
    '81' => {
        'insert' => '401.000ps ',
        'expect' => '4.01e-010'
    },
    '137' => {
        'insert' => '97.590mV ',
        'expect' => '0.09759'
    },
    '60' => {
        'insert' => '1.324pF ',
        'expect' => '1.324e-012'
    },
    '86' => {
        'insert' => '134.000ps ',
        'expect' => '1.34e-010'
    },
    '247' => {
        'insert' => '-35.000mA ',
        'expect' => '-0.035'
    },
    '204' => {
        'insert' => '387.000mV ',
        'expect' => '0.387'
    },
    '165' => {
        'insert' => '542.000mV ',
        'expect' => '0.542'
    },
    '17' => {
        'insert' => '2.044pF ',
        'expect' => '2.044e-012'
    },
    '2' => {
        'insert' => '-910.000mV ',
        'expect' => '-0.91'
    },
    '186' => {
        'insert' => '12.630mA ',
        'expect' => '0.01263'
    },
    '82' => {
        'insert' => '69.000ps ',
        'expect' => '6.9e-011'
    },
    '110' => {
        'insert' => '529.000mV ',
        'expect' => '0.529'
    },
    '147' => {
        'insert' => '2.051pF ',
        'expect' => '2.051e-012'
    },
    '228' => {
        'insert' => '670.000mV ',
        'expect' => '0.67'
    },
    '268' => {
        'insert' => '18.980mA ',
        'expect' => '0.01898'
    },
    '69' => {
        'insert' => '17.000ps ',
        'expect' => '1.7e-011'
    },
    '112' => {
        'insert' => '686.000mV ',
        'expect' => '0.686'
    },
    '172' => {
        'insert' => '692.000mV ',
        'expect' => '0.692'
    },
    '191' => {
        'insert' => '1.100V ',
        'expect' => '1.100 '
    },
    '224' => {
        'insert' => '521.000mV ',
        'expect' => '0.521'
    },
    '187' => {
        'insert' => '135.000mV ',
        'expect' => '0.135'
    },
    '223' => {
        'insert' => '110.000mA ',
        'expect' => '0.11'
    },
    '262' => {
        'insert' => '577.000mV ',
        'expect' => '0.577'
    },
    '79' => {
        'insert' => '1.640V ',
        'expect' => '1.640 '
    },
    '121' => {
        'insert' => '1.162V ',
        'expect' => '1.162 '
    },
    '212' => {
        'insert' => '369.600uA ',
        'expect' => '0.0003696'
    },
    '126' => {
        'insert' => '440.000mV ',
        'expect' => '0.44'
    },
    '238' => {
        'insert' => '932.000mV ',
        'expect' => '0.932'
    },
    '251' => {
        'insert' => '696.000mV ',
        'expect' => '0.696'
    },
    '253' => {
        'insert' => '4.129mA ',
        'expect' => '0.004129'
    },
    '176' => {
        'insert' => '17.300uA ',
        'expect' => '1.73e-005'
    },
    '209' => {
        'insert' => '6.490mA ',
        'expect' => '0.00649'
    },
    '216' => {
        'insert' => '357.000mV ',
        'expect' => '0.357'
    },
    '256' => {
        'insert' => '170.000uV ',
        'expect' => '0.00017'
    },
    '117' => {
        'insert' => '607.000mV ',
        'expect' => '0.607'
    },
    '170' => {
        'insert' => '540.000mV ',
        'expect' => '0.54'
    },
    '33' => {
        'insert' => '2.013pF ',
        'expect' => '2.013e-012'
    },
    '63' => {
        'insert' => '1.860pF ',
        'expect' => '1.86e-012'
    },
    '7' => {
        'insert' => '124.000ps ',
        'expect' => '1.24e-010'
    },
    '80' => {
        'insert' => '2.127pF ',
        'expect' => '2.127e-012'
    },
    '26' => {
        'insert' => '39.000ps ',
        'expect' => '3.9e-011'
    },
    '227' => {
        'insert' => '98.360mV ',
        'expect' => '0.09836'
    },
    '99' => {
        'insert' => '1.200V ',
        'expect' => '1.200 '
    },
    '72' => {
        'insert' => '173.000ps ',
        'expect' => '1.73e-010'
    },
    '179' => {
        'insert' => '546.000mV ',
        'expect' => '0.546'
    },
    '264' => {
        'insert' => '3.722uA ',
        'expect' => '3.722e-006'
    },
    '255' => {
        'insert' => '460.000mV ',
        'expect' => '0.46'
    },
    '182' => {
        'insert' => '455.360fF ',
        'expect' => '4.5536e-013'
    },
    '108' => {
        'insert' => '367.000mV ',
        'expect' => '0.367'
    },
    '92' => {
        'insert' => '439.000ps ',
        'expect' => '4.39e-010'
    },
    '232' => {
        'insert' => '1.260V ',
        'expect' => '1.260 '
    },
    '10' => {
        'insert' => '243.000ps ',
        'expect' => '2.43e-010'
    },
    '225' => {
        'insert' => '3.711mA ',
        'expect' => '0.003711'
    },
    '142' => {
        'insert' => '1.200V ',
        'expect' => '1.200 '
    },
    '207' => {
        'insert' => '15.180mA ',
        'expect' => '0.01518'
    },
    '263' => {
        'insert' => '597.000mV ',
        'expect' => '0.597'
    },
    '167' => {
        'insert' => '1.033mA ',
        'expect' => '0.001033'
    },
    '48' => {
        'insert' => '559.000ps ',
        'expect' => '5.59e-010'
    },
    '133' => {
        'insert' => '91.950mA ',
        'expect' => '0.09195'
    },
    '123' => {
        'insert' => '13.190mA ',
        'expect' => '0.01319'
    },
    '149' => {
        'insert' => '884.000mV ',
        'expect' => '0.884'
    },
    '50' => {
        'insert' => '63.000ps ',
        'expect' => '6.3e-011'
    },
    '210' => {
        'insert' => '685.000mV ',
        'expect' => '0.685'
    },
    '258' => {
        'insert' => '1.146V ',
        'expect' => '1.146 '
    },
    '173' => {
        'insert' => '1.083V ',
        'expect' => '1.083 '
    },
    '56' => {
        'insert' => '140.000ps ',
        'expect' => '1.4e-010'
    },
    '66' => {
        'insert' => '-630.000mV ',
        'expect' => '-0.63'
    },
    '19' => {
        'insert' => '272.000ps ',
        'expect' => '2.72e-010'
    },
    '54' => {
        'insert' => '-1.010V ',
        'expect' => '-1.010 '
    },
    '274' => {
        'insert' => '511.000mV ',
        'expect' => '0.511'
    },
    '70' => {
        'insert' => '37.000ps ',
        'expect' => '3.7e-011'
    },
    '166' => {
        'insert' => '651.000mV ',
        'expect' => '0.651'
    },
    '88' => {
        'insert' => '-90.000mV ',
        'expect' => '-0.09'
    },
    '30' => {
        'insert' => '264.000ps ',
        'expect' => '2.64e-010'
    },
    '141' => {
        'insert' => '3.482mV ',
        'expect' => '0.003482'
    },
    '128' => {
        'insert' => '13.130mA ',
        'expect' => '0.01313'
    },
    '252' => {
        'insert' => '584.800uA ',
        'expect' => '0.0005848'
    },
    '28' => {
        'insert' => '287.000ps ',
        'expect' => '2.87e-010'
    },
    '75' => {
        'insert' => '96.000ps ',
        'expect' => '9.6e-011'
    },
    '40' => {
        'insert' => '90.000ps ',
        'expect' => '9e-011'
    },
    '134' => {
        'insert' => '475.000mV ',
        'expect' => '0.475'
    },
    '156' => {
        'insert' => '1.178V ',
        'expect' => '1.178 '
    },
    '192' => {
        'insert' => '664.000mV ',
        'expect' => '0.664'
    },
    '250' => {
        'insert' => '576.000mV ',
        'expect' => '0.576'
    },
    '59' => {
        'insert' => '457.000ps ',
        'expect' => '4.57e-010'
    },
    '215' => {
        'insert' => '14.720mA ',
        'expect' => '0.01472'
    },
    '150' => {
        'insert' => '9.080mA ',
        'expect' => '0.00908'
    },
    '271' => {
        'insert' => '10.730uA ',
        'expect' => '1.073e-005'
    },
    '130' => {
        'insert' => '1.885pF ',
        'expect' => '1.885e-012'
    },
    '155' => {
        'insert' => '644.200uA ',
        'expect' => '0.0006442'
    },
    '53' => {
        'insert' => '84.847mV ',
        'expect' => '0.084847'
    },
    '245' => {
        'insert' => '1.241V ',
        'expect' => '1.241 '
    },
    '267' => {
        'insert' => '701.000mV ',
        'expect' => '0.701'
    },
    '219' => {
        'insert' => '655.000mV ',
        'expect' => '0.655'
    },
    '13' => {
        'insert' => '193.000ps ',
        'expect' => '1.93e-010'
    },
    '257' => {
        'insert' => '743.000mV ',
        'expect' => '0.743'
    },
    '105' => {
        'insert' => '686.000mV ',
        'expect' => '0.686'
    },
    '85' => {
        'insert' => '178.000ps ',
        'expect' => '1.78e-010'
    },
    '3' => {
        'insert' => '189.000ps ',
        'expect' => '1.89e-010'
    },
    '185' => {
        'insert' => '664.000mV ',
        'expect' => '0.664'
    },
    '248' => {
        'insert' => '13.250mA ',
        'expect' => '0.01325'
    },
    '111' => {
        'insert' => '14.390mA ',
        'expect' => '0.01439'
    },
    '9' => {
        'insert' => '625.000ps ',
        'expect' => '6.25e-010'
    },
    '146' => {
        'insert' => '304.400uV ',
        'expect' => '0.0003044'
    },
    '38' => {
        'insert' => '-1.050V ',
        'expect' => '-1.050 '
    },
    '4' => {
        'insert' => '1.324pF ',
        'expect' => '1.324e-012'
    },
    '34' => {
        'insert' => '448.000ps ',
        'expect' => '4.48e-010'
    },
    '164' => {
        'insert' => '72.520mA ',
        'expect' => '0.07252'
    },
    '196' => {
        'insert' => '29.920uA ',
        'expect' => '2.992e-005'
    },
    '242' => {
        'insert' => '11.490mA ',
        'expect' => '0.01149'
      }

);

my %test0 = (

    'insert' => "1",
    'expect' => 1

);

my %test1 = (

    'insert' => "1.",
    'expect' => NULL_VAL

);

my %test2 = (

    'insert' => "1.1",
    'expect' => 1.1

);

my %test3 = (

    'insert' => "1.12344567",
    'expect' => 1.12344567

);

my %test4 = (

    'insert' => "1.166V",
    'expect' => 1.166

);

my %test5 = (

    'insert' => "1.V",
    'expect' => NULL_VAL

);

my %test6 = (

    'insert' => "1.v",
    'expect' => NULL_VAL

);

my %test7 = (

    'insert' => "1.23V",
    'expect' => 1.23

);

my %test8 = (

    'insert' => "1.23v",
    'expect' => 1.23

);

my %test9 = (

    'insert' => "1.23mv",
    'expect' => 0.00123

);

my %test10 = (

    'insert' => "1.23mV",
    'expect' => 0.00123

);

my %test11 = (
    'insert' => "1uV",
    'expect' => 0.000001
);

my %test12 = (
    'insert' => "1uv",
    'expect' => 0.000001
);

my %test13 = (
    'insert' => "1nv",
    'expect' => 0.000000001
);

my %test14 = (
    'insert' => "1pv",
    'expect' => 0.000000000001
);

my %test15 = (
    'insert' => "1fv",
    'expect' => 0.000000000000001
);

my %test16 = (
    'insert' => "1.10fv",
    'expect' => 0.0000000000000011
);

my %test17 = (
    'insert' => "1ma",
    'expect' => 0.001
);

my %test18 = (
    'insert' => "1ua",
    'expect' => 0.000001
);

my %test19 = (
    'insert' => "1na",
    'expect' => 0.000000001
);

my %test20 = (
    'insert' => "1pa",
    'expect' => 0.000000000001
);

my %test21 = (
    'insert' => "1fa",
    'expect' => 0.000000000000001
);

my %test22 = (
    'insert' => "1a",
    'expect' => 1
);

my %test23 = (
    'insert' => "1f",
    'expect' => 1
);

my %test24 = (
    'insert' => "1mf",
    'expect' => 0.001
);

my %test25 = (
    'insert' => "1uf",
    'expect' => 0.000001
);

my %test26 = (
    'insert' => "1nf",
    'expect' => 0.000000001
);

my %test27 = (
    'insert' => "1pf",
    'expect' => 0.000000000001
);

my %test28 = (
    'insert' => "1ff",
    'expect' => 0.000000000000001
);

my %test29 = (
    'insert' => "1s",
    'expect' => 1
);

my %test30 = (
    'insert' => "1ms",
    'expect' => 0.001
);

my %test31 = (
    'insert' => "1us",
    'expect' => 0.000001
);

my %test32 = (
    'insert' => "1n",
    'expect' => NULL_VAL
);

my %test33 = (
    'insert' => "1ps",
    'expect' => 0.000000000001
);

my %test34 = (
    'insert' => "1fs",
    'expect' => 0.000000000000001
);

my %test35 = (
    'insert' => "123.456",
    'expect' => 123.456
);

my %test36 = (
    'insert' => "1a",
    'expect' => 1
);

my %test37 = (
    'insert' => "1f",
    'expect' => 1
);

my %test38 = (
    'insert' => "3s",
    'expect' => 3
);

my %test39 = (
    'insert' => "4v",
    'expect' => 4
);

my %test40 = (
    'insert' => "ABCDEFpv",
    'expect' => NULL_VAL
);

our @POSITIVE_VECTOR = (
    \%test0,  \%test1,  \%test2,  \%test3,  \%test4,  \%test5,  \%test6,
    \%test7,  \%test8,  \%test9,  \%test10, \%test11, \%test12, \%test13,
    \%test14, \%test15, \%test16, \%test17, \%test18, \%test19, \%test20,
    \%test21, \%test22, \%test23, \%test24, \%test25, \%test26, \%test27,
    \%test28, \%test29, \%test30, \%test31, \%test32, \%test33, \%test34,
    \%test35, \%test36, \%test37, \%test38, \%test39, \%test40
);

my %m_test0 = (

    'insert' => "-1",
    'expect' => -1

);

my %m_test1 = (

    'insert' => "-1.",
    'expect' => NULL_VAL

);

my %m_test2 = (

    'insert' => "-1.1",
    'expect' => -1.1

);

my %m_test3 = (

    'insert' => "-1.12344567",
    'expect' => -1.12344567

);

my %m_test4 = (

    'insert' => "-1.166V",
    'expect' => -1.166

);

my %m_test5 = (

    'insert' => "-1.V",
    'expect' => NULL_VAL

);

my %m_test6 = (

    'insert' => "-1.v",
    'expect' => NULL_VAL

);

my %m_test7 = (

    'insert' => "-1.23V",
    'expect' => -1.23

);

my %m_test8 = (

    'insert' => "-1.23v",
    'expect' => -1.23

);

my %m_test9 = (

    'insert' => "-1.23mv",
    'expect' => -0.00123

);

my %m_test10 = (

    'insert' => "-1.23mV",
    'expect' => -0.00123

);

my %m_test11 = (
    'insert' => "-1uV",
    'expect' => -0.000001
);

my %m_test12 = (
    'insert' => "-1uv",
    'expect' => -0.000001
);

my %m_test13 = (
    'insert' => "-1nv",
    'expect' => -0.000000001
);

my %m_test14 = (
    'insert' => "-1pv",
    'expect' => -0.000000000001
);

my %m_test15 = (
    'insert' => "-1fv",
    'expect' => -0.000000000000001
);

my %m_test16 = (
    'insert' => "-1.10fv",
    'expect' => -0.0000000000000011
);

my %m_test17 = (
    'insert' => "-1ma",
    'expect' => -0.001
);

my %m_test18 = (
    'insert' => "-1ua",
    'expect' => -0.000001
);

my %m_test19 = (
    'insert' => "-1na",
    'expect' => -0.000000001
);

my %m_test20 = (
    'insert' => "-1pa",
    'expect' => -0.000000000001
);

my %m_test21 = (
    'insert' => "-1fa",
    'expect' => -0.000000000000001
);

my %m_test22 = (
    'insert' => "-1a",
    'expect' => -1
);

my %m_test23 = (
    'insert' => "-1f",
    'expect' => -1
);

my %m_test24 = (
    'insert' => "-1mf",
    'expect' => -0.001
);

my %m_test25 = (
    'insert' => "-1uf",
    'expect' => -0.000001
);

my %m_test26 = (
    'insert' => "-1nf",
    'expect' => -0.000000001
);

my %m_test27 = (
    'insert' => "-1pf",
    'expect' => -0.000000000001
);

my %m_test28 = (
    'insert' => "-1ff",
    'expect' => -0.000000000000001
);

my %m_test29 = (
    'insert' => "-1s",
    'expect' => -1
);

my %m_test30 = (
    'insert' => "-1ms",
    'expect' => -0.001
);

my %m_test31 = (
    'insert' => "-1us",
    'expect' => -0.000001
);

my %m_test32 = (
    'insert' => "-1n",
    'expect' => NULL_VAL
);

my %m_test33 = (
    'insert' => "-1ps",
    'expect' => -0.000000000001
);

my %m_test34 = (
    'insert' => "-1fs",
    'expect' => -0.000000000000001
);

my %m_test35 = (
    'insert' => "-123.456",
    'expect' => -123.456
);

my %m_test36 = (
    'insert' => "-1a",
    'expect' => -1
);

my %m_test37 = (
    'insert' => "-1f",
    'expect' => -1
);

my %m_test38 = (
    'insert' => "-3s",
    'expect' => -3
);

my %m_test39 = (
    'insert' => "-4v",
    'expect' => -4
);

my %m_test40 = (
    'insert' => "-ABCDEFpv",
    'expect' => NULL_VAL
);

our @NEGATIVE_VECTOR = (
    \%m_test0,  \%m_test1,  \%m_test2,  \%m_test3,  \%m_test4,  \%m_test5,
    \%m_test6,  \%m_test7,  \%m_test8,  \%m_test9,  \%m_test10, \%m_test11,
    \%m_test12, \%m_test13, \%m_test14, \%m_test15, \%m_test16, \%m_test17,
    \%m_test18, \%m_test19, \%m_test20, \%m_test21, \%m_test22, \%m_test23,
    \%m_test24, \%m_test25, \%m_test26, \%m_test27, \%m_test28, \%m_test29,
    \%m_test30, \%m_test31, \%m_test32, \%m_test33, \%m_test34, \%m_test35,
    \%m_test36, \%m_test37, \%m_test38, \%m_test39, \%m_test40
);

################################
# A package must return "TRUE" #
################################

1;

__END__