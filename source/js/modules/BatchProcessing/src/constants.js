const constants = {
  APP_PATH: '/batch',
  STAGE_BASE: 'https://stage-sagesure-svc.icg360.org/cru-4',
  PROD_BASE: 'https://services.sagesure.com/cru-4',
  dates: {
    SYSTEM_FORMAT: 'YYYY-MM-DDThh:mm:ss.SSSZ',
    USER_FORMAT: 'MMM DD, YYYY h:mm A',
    DATEPICKER_FORMAT: 'YYYY-MM-DD'
  },
  messages: {
    errors: {
      xhr: {
        DEFAULT: 'The server is temporarily unable to service your request due to maintenance downtime or capacity problems. Please contact the help desk if the problem persists.',
        0: 'The server is currently unresponsive. Please contact the help desk if the problem persists.'
      }
    }
  }
};

export default constants;
