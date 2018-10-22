import { registerHelper } from 'discourse-common/lib/helpers';

export default registerHelper("eq", function(params) {
  return params[0] == params[1];
});

registerHelper("frlGroupName", function(params) {
  const groups = params[0];
  const group = params[0].findBy("id", params[1]);

  if (!group) return;

  return group.full_name || group.name;
});

registerHelper("frlGetCategory", function(params) {
  const categories = Discourse.__container__.lookup("site:main").get("categories");
  return categories.findBy("id", params[0]);
});
