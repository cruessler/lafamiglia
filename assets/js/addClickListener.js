// The following is from `phoenix_html`.
//
// It is included here because `bootstrap`’s handler for dropdown menus
// interferes with the way `phoenix_html` attaches its event handler to catch
// `click` events on <a> tags.
//
// Specifically, `bootstrap` adds a [listener] that calls `stopPropagation` for
// all <form> tags inside of a dropdown menu.
//
// [listener]: https://github.com/twbs/bootstrap-sass/blob/b34765d8a6aa775816c59012b2d6b30c4c66a8e9/assets/javascripts/bootstrap.js#L920

const isLinkToSubmitParent = (element) => {
  const isLinkTag = element.tagName === 'A';
  const shouldSubmitParent = element.getAttribute('data-submit') === 'parent';

  return isLinkTag && shouldSubmitParent;
};

const didHandleSubmitLinkClick = (element) => {
  while (element && element.getAttribute) {
    if (isLinkToSubmitParent(element)) {
      const message = element.getAttribute('data-confirm');
      if (message === null || confirm(message)) {
        element.parentNode.submit();
      }
      return true;
    } else {
      element = element.parentNode;
    }
  }
  return false;
};

// This is the only place where there is a difference to `phoenix_html`. By
// attaching the handler directly to the element, we are the first to get it.
document.querySelectorAll('a[data-submit]').forEach((node) =>
  node.addEventListener(
    'click',
    (event) => {
      if (event.target && didHandleSubmitLinkClick(event.target)) {
        event.preventDefault();
        return false;
      }
    },
    false
  )
);
