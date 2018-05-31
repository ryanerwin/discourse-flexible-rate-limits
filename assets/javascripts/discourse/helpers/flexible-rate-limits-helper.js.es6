import { registerHelper } from 'discourse-common/lib/helpers';

export default registerHelper("eq", function(params) {
  return params[0] == params[1];
});

registerHelper("groupName", function(params) {
  const groups = params[0];
  const group = params[0].findBy("id", params[1].id);

  if (!group) return;

  return group.full_name || group.name;
});