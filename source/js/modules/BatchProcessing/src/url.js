function getUrlRoot(ENV, APP_PATH, STAGE_BASE, PROD_BASE) {
  const base = ENV === 'PROD' ? PROD_BASE : STAGE_BASE;
  return `${base}${APP_PATH}`;
}

export default getUrlRoot;
