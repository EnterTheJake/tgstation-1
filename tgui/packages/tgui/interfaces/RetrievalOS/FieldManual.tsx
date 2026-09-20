import { type ReactNode, useContext } from 'react';
import { GlitchContext } from './glitch';

const STEPS: [string, ReactNode][] = [
  [
    'DESIGNATE TARGET',
    <>
      Your <em>handler</em> will provide a target to locate.
    </>,
  ],
  ['LOCATE TARGET', 'Utilize your tools to find your target.'],
  ['SUBDUE TARGET', 'Assist in rendering your target immobile.'],
  ['SECURE TARGET', 'Place the target in your Holding Chamber.'],
  [
    'TRANSPORT TARGET',
    <>
      Bring your target to your <em>handler's</em> chosen dropoff.
    </>,
  ],
];

const BREAKS: [string, ReactNode, boolean?][] = [
  [
    'Utilizing tools or modules',
    'Onboard equipment usage will interrupt the field.',
  ],
  [
    'You are incapacitated',
    'This includes being flipped over and sudden drops.',
  ],
  ['You suffer integrity loss', 'Structural damage will disable the field.'],
  [
    'Activating your Hover Jets',
    'The hover jets actively disrupt attempts to maintain the field.',
  ],
  [
    'Placing someone into the Holding Chamber',
    'Unless they have a Cybersun Authorization Implant.',
  ],
  [
    'Someone bumps into you, causing a brief disruption',
    'This does not fully remove the field, but can reveal your presence.',
    true,
  ],
];

const LIFE_SUPPORT: [string, string][] = [
  ['INJURY', 'Select a damage type to slowly heal physical trauma.'],
  ['AIR SUPPLY', 'The onboard life support creates a breathable atmosphere.'],
  [
    'BLOOD',
    'Select blood to reverse blood loss through synthblood injections.',
  ],
  ['TEMPERATURE', 'Select core temperature to normalize thermal regulation.'],
];

const KIT: [string, string][] = [
  ['Integrated Taser', 'Rapidly incapacitates a single person.'],
  ['Flash', 'Creates a disruptive flash of light, scrambling optical sensors.'],
  ['Zipties', 'For restraining a target.'],
  ['RCD', 'Rapid Construction Device. Creation of doors, walls and windows.'],
  ['RTD', 'Rapid Tiling Device. Rapid placing and removal of floor tiles.'],
  ['Omnitools', 'Toolset arms used in construction or machine manipulation.'],
];

type CardProps = {
  icon: string;
  name: string;
  children: ReactNode;
};

const Card = (props: CardProps) => {
  const { g } = useContext(GlitchContext);
  return (
    <div className="card">
      <div className="card__icon">{props.icon}</div>
      <div className="card__body">
        <div className="card__name">
          {g(props.name, `card-${props.name}`, true)}
        </div>
        <div className="card__tip">{props.children}</div>
      </div>
    </div>
  );
};

const SectionLabel = (props: { children: string }) => {
  const { g } = useContext(GlitchContext);
  return (
    <div className="section-label">
      {g(props.children, `label-${props.children}`, true)}
    </div>
  );
};

export const FieldManual = () => {
  const { g } = useContext(GlitchContext);
  return (
    <div className="manual">
      <div className="briefing">
        <div className="briefing__eyebrow">
          Contract Acquisition Square Helper · Orientation
        </div>
        <div className="briefing__title">
          Prime Directive: <b>ACQUISITION</b>
        </div>
        <div className="briefing__lead">
          <p>
            You are a <em>synthetic positronic brain</em> housed inside a
            cybernetic chassis.
          </p>
          <p>
            You were created to assist your designated <em>handler</em>, a{' '}
            <em>Cybersun Industries contractor</em>, in the live capture of
            valuable <em>persons of interest</em> to the company.
          </p>
          <p>
            Pursue the targets designated by your <em>handler</em>. Ensure they
            are captured <em>alive</em>.
          </p>
          <p>
            Ensure that your <em>handler</em> is <em>safe</em>.
          </p>
          <p>
            You are not permitted self-determination. Your <em>handler</em>{' '}
            knows best.
          </p>
          <p>
            Your <em>handler</em> gives you purpose. Obey your <em>handler</em>.
          </p>
        </div>
      </div>

      <SectionLabel>Objectives</SectionLabel>
      <div className="steps">
        {STEPS.map(([name, desc], index) => (
          <div className="step" key={name}>
            <div className="step__no">
              {g(`0${index + 1}`, `step-no-${index}`)}
            </div>
            <div className="step__name">{g(name, `step-${index}`, true)}</div>
            <div className="step__desc">{desc}</div>
          </div>
        ))}
      </div>

      <SectionLabel>Systems</SectionLabel>
      <Card icon="◊" name="Stealth Field Generator">
        You possess a stealth field generator that bends light around you,
        preventing visual identification. The field cannot be utilized while in{' '}
        <em>hover mode</em>, and can be disrupted through physical contact or
        attempting to interact with other entities physically. You can utilize
        the field with a passenger inside of your Holding Chamber{' '}
        <em>only if they have a Cybersun Authorization Implant</em>.
      </Card>
      <Card icon="▲" name="Hover Jets">
        Your hover jets allow you to traverse quickly through space, as well as
        standard gravity. Some actions cannot be performed while hovering. Also
        protects you from ground-based dangers.
      </Card>
      <Card icon="◉" name="Holding Chamber">
        You can place <em>people</em> inside of your internal transportation
        chamber. Click and drag them onto yourself to start placing them inside.
        If they are{' '}
        <em>
          incapacitated, helpless, restrained or have a Cybersun Authorization
          Implant,
        </em>{' '}
        they are instantly placed inside. Otherwise, it requires performing a
        brief interaction timer before they are placed within. Passengers
        without a <em>Cybersun Authorization Implant</em> will be subjected to
        various soporific toxins and smooth jazz music, eventually placing them
        in a deep slumber.
      </Card>
      <Card icon="◎" name="Thermal Optics">
        Your thermal vision is always active, allowing you to see entities
        through walls.
      </Card>
      <Card icon="⌖" name="Bounty Board">
        You have access to the same bounty board as your <em>handler</em>.
        However, as a Contract Acquisition Square Helper,{' '}
        <em>Cybersun Industries</em> cannot accept your requests for acquisition
        due to <em>Ichikawa's Rules of Synthetic Hierarchy</em> forbidding
        synthetic entities the <em>right of profitable self-determination</em>.
        You can, however, request extraction pods to be sent to your current
        location to extract the target designated by your <em>handler</em>.
        <p>
          Remember Rule 1 of Synthetic Hierarchy:{' '}
          <em>You exist to the benefit of your handler.</em>
        </p>
      </Card>

      <SectionLabel>What Disables the Stealth Field</SectionLabel>
      <div className="breaks">
        {BREAKS.map(([what, how, soft]) => (
          <div className={`brk ${soft ? 'brk--soft' : ''}`} key={what}>
            <div className="brk__what">{what}</div>
            <div className="brk__how">{how}</div>
          </div>
        ))}
      </div>

      <SectionLabel>Holding Chamber Life Support</SectionLabel>
      <div className="rates">
        {LIFE_SUPPORT.map(([unit, what]) => (
          <div className="rate" key={unit}>
            <div className="rate__unit">{unit}</div>
            <div className="rate__what">{what}</div>
          </div>
        ))}
      </div>
      <Card icon="≡" name="Life Support Threads">
        Life support runs <em>three threads</em>: damage, body and organs. Each
        thread repairs <em>one selection</em> at a time. Select a row in the
        Occupant tab to start a thread. Select the row again to stop it. A
        thread <em>stops by itself</em> when its repair is complete, and does
        not start again until you select a row. Each running thread drains power
        reserves.
      </Card>
      <Card icon="♥" name="REVIVAL MATRIX">
        A critical component of the onboard life support systems is the revival
        matrix, allowing for the resuscitation of held subjects within the
        Holding Chamber. The matrix cannot restart a heart while the body has{' '}
        <em>severe tissue damage</em>, a <em>failing heart</em> or a{' '}
        <em>failing brain</em>. Direct life support to repair these first. Then{' '}
        <em>charge</em> the matrix and <em>discharge</em> a defibrillating
        shock. This process will be slow. However, it will ensure targets, and
        most importantly, your <em>handler</em>, can be recovered in the event
        of their demise. This process cannot restore lost limbs, including a
        destroyed or removed brain.
        <p>
          The mind is a terrible thing to <em>lose</em>.
        </p>
      </Card>

      <SectionLabel>Toolkit</SectionLabel>
      <div className="kit">
        {KIT.map(([name, use]) => (
          <div className="kit__row" key={name}>
            <span className="kit__name">{name}</span>
            <span className="kit__use">{use}</span>
          </div>
        ))}
      </div>

      <div className="notice notice--caution">
        <b>⚠ CAUTION</b>
        Avoid idling with your Hover Jets, Stealth Field Generator or life
        support threads active. This is an inefficient use of power reserves.
      </div>
      <div className="notice notice--note">
        <b>NOTE</b>
        Allow your <em>handler</em> to access your panel. <em>Do not</em> allow
        unauthorized personnel to access your panel.
      </div>
    </div>
  );
};
