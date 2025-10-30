# Processor Feature - Live Demo Summary

## What Just Happened

We demonstrated the processor feature working live! Here's the complete flow:

### 1. Schema Configuration

**File: `examples/simple_demo.yml`**

```yaml
release_version:
  type: select
  prompt: "Select your release version"
  options: ["3.1.5.1", "3.1.5.3", "3.2.0.0"]

feature_flags:
  type: multi_select
  prompt: "Select feature flags"
  source:
    type: "processor"                      # ← Uses processor!
    class: "FeatureFlagProcessor"          # ← Our custom class
    method: "filter_by_release"            # ← Our custom method
    data_file: "examples/features.yml"     # ← Custom config
```

### 2. Data File

**File: `examples/features.yml`**

```yaml
feature_flags:
  releases:
    "3.1.5.0": [flag1, flag2]
    "3.1.5.1": [flag3, flag4]
    "3.1.5.2": [flag5, flag6]
    "3.1.5.3": [flag7, flag8]
```

### 3. Processor Implementation

**File: `examples/processors/feature_flag_processor.rb`**

```ruby
class FeatureFlagProcessor
  def self.filter_by_release(answers:, config:)
    features = YAML.load_file(config['data_file'])
    release_version = answers['release_version']

    # Return cumulative flags up to selected version
    version_mapping = {
      '3.1.5.1' => ['3.1.5.0', '3.1.5.1'],
      '3.1.5.3' => ['3.1.5.0', '3.1.5.1', '3.1.5.2', '3.1.5.3'],
      '3.2.0.0' => :all
    }

    # ... filtering logic ...
    flags
  end
end
```

### 4. Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Step 1: User runs Prompter                                 │
├─────────────────────────────────────────────────────────────┤
│  $ ruby -r ./examples/processors/feature_flag_processor.rb  │
│         -I./lib ./bin/prompter                              │
│         examples/simple_demo.yml                            │
│         examples/demo_output.yml                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 2: Prompter asks first question                       │
├─────────────────────────────────────────────────────────────┤
│  ? Select your release version                              │
│    ‣ 3.1.5.1                                                │
│      3.1.5.3                                                │
│      3.2.0.0                                                │
├─────────────────────────────────────────────────────────────┤
│  User selects: 3.1.5.1                                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 3: Prompter reaches feature_flags field               │
├─────────────────────────────────────────────────────────────┤
│  - Sees source.type = "processor"                           │
│  - Calls FeatureFlagProcessor.filter_by_release with:       │
│    answers: { 'release_version' => '3.1.5.1' }              │
│    config: { 'data_file' => 'examples/features.yml' }       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 4: Processor executes                                 │
├─────────────────────────────────────────────────────────────┤
│  - Loads features.yml                                       │
│  - Sees release_version = '3.1.5.1'                         │
│  - Determines to include: 3.1.5.0 + 3.1.5.1                 │
│  - Returns: ['flag1', 'flag2', 'flag3', 'flag4']            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 5: User sees dynamically filtered options             │
├─────────────────────────────────────────────────────────────┤
│  ? Select feature flags                                     │
│    ⬡ flag1   ← Only these 4 options appear!                 │
│    ⬡ flag2   ← Processor filtered based on version          │
│    ⬡ flag3                                                  │
│    ⬡ flag4                                                  │
│                                                             │
│  (flags 5-8 not shown because version 3.1.5.1 doesn't      │
│   include releases 3.1.5.2 and 3.1.5.3)                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 6: Output saved                                       │
├─────────────────────────────────────────────────────────────┤
│  File: examples/demo_output.yml                             │
│                                                             │
│  ---                                                        │
│  release_version: 3.1.5.1                                   │
│  feature_flags:                                             │
│    - flag1                                                  │
└─────────────────────────────────────────────────────────────┘
```

## Key Takeaways

### Dynamic Filtering Works!

- When user selected **3.1.5.1**, processor returned **4 flags**
- When user selects **3.1.5.3**, processor would return **8 flags**
- When user selects **3.2.0.0**, processor would return **all flags**

### Context-Aware Prompts

The processor has access to **all previous answers**, enabling:
- Conditional options based on earlier choices
- Cross-field validation
- Complex business logic
- API calls, database queries, file reads, etc.

### Clean Separation

- **Schema** defines structure
- **Processor** implements logic
- **Data files** store configuration
- Everything is testable and reusable!

## Try It Yourself

### Option 1: Automated Demo (No Input Required)

```bash
ruby examples/demo_automated.rb
```

Shows all three scenarios with detailed explanation.

### Option 2: Interactive Demo

```bash
ruby -r ./examples/processors/feature_flag_processor.rb \
     -I./lib \
     ./bin/prompter \
     examples/simple_demo.yml \
     examples/output.yml
```

You'll be prompted to:
1. Select a release version
2. Select feature flags (filtered by your choice)

### Option 3: Full Feature Demo

```bash
ruby -r ./examples/processors/feature_flag_processor.rb \
     -I./lib \
     ./bin/prompter \
     examples/processor_test.yml \
     examples/output.yml
```

Includes additional fields like environment, monitoring, etc.

## Different Scenarios

### Scenario A: Select 3.1.5.1
```
Available flags: flag1, flag2, flag3, flag4
(Cumulative from 3.1.5.0 + 3.1.5.1)
```

### Scenario B: Select 3.1.5.3
```
Available flags: flag1, flag2, flag3, flag4, flag5, flag6, flag7, flag8
(Cumulative from 3.1.5.0 + 3.1.5.1 + 3.1.5.2 + 3.1.5.3)
```

### Scenario C: Select 3.2.0.0
```
Available flags: flag1, flag2, flag3, flag4, flag5, flag6, flag7, flag8
(All available flags)
```

## The Power of Processors

This simple example demonstrates:

1. **Dynamic options** - Options change based on previous answers
2. **External data** - Loads from YAML file (could be API, database, etc.)
3. **Business logic** - Implements version-based filtering
4. **Reusability** - Same processor can be used in multiple schemas
5. **Testability** - Processor is a plain Ruby class
6. **Flexibility** - Can implement any logic you need

## Next Steps

1. **Customize** the processor for your use case
2. **Add more** processors for different scenarios
3. **Connect** to APIs, databases, or other data sources
4. **Test** your processors independently
5. **Reuse** across multiple schemas

The processor architecture gives you unlimited flexibility while keeping your schemas clean and maintainable!
