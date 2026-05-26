type Props = {
  errors?: Array<string>;
};

export const CreateTaskForm = (props: Props) => {
  return (
    <form
      class="add-task"
      hx-post="/tasks"
      hx-target="previous ul"
      hx-swap="outerHTML"
      hx-on--after-request="if(event.detail.successful) this.reset()"
    >
      <input
        type="text"
        name="title"
        placeholder="New task..."
        maxlength={100}
      />
      <button type="submit">Add</button>
      {props.errors && props.errors.length > 0 && (
        <ul class="errors">
          {props.errors.map((e) => (
            <li>{e}</li>
          ))}
        </ul>
      )}
    </form>
  );
};
