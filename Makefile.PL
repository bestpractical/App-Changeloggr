use inc::Module::Install;

name        'App-Changeloggr';
version     '0.01';

requires    'Jifty' => '0.90220';
requires    'JiftyX::ModelHelpers' => '0.22';
requires    'Data::GUID';
requires    'Params::Validate';

WriteAll;
