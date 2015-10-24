import $script from 'scriptjs';
import {version} from '../package.json';

$script(`../js/modules/BatchProcessing/public/build.js?${version}`);
