
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Application Discovery Service
## version: 2015-11-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Application Discovery Service</fullname> <p>AWS Application Discovery Service helps you plan application migration projects by automatically identifying servers, virtual machines (VMs), software, and software dependencies running in your on-premises data centers. Application Discovery Service also collects application performance data, which can help you assess the outcome of your migration. The data collected by Application Discovery Service is securely retained in an AWS-hosted and managed database in the cloud. You can export the data as a CSV or XML file into your preferred visualization tool or cloud-migration solution to plan your migration. For more information, see <a href="http://aws.amazon.com/application-discovery/faqs/">AWS Application Discovery Service FAQ</a>.</p> <p>Application Discovery Service offers two modes of operation:</p> <ul> <li> <p> <b>Agentless discovery</b> mode is recommended for environments that use VMware vCenter Server. This mode doesn't require you to install an agent on each host. Agentless discovery gathers server information regardless of the operating systems, which minimizes the time required for initial on-premises infrastructure assessment. Agentless discovery doesn't collect information about software and software dependencies. It also doesn't work in non-VMware environments. </p> </li> <li> <p> <b>Agent-based discovery</b> mode collects a richer set of data than agentless discovery by using the AWS Application Discovery Agent, which you install on one or more hosts in your data center. The agent captures infrastructure and application information, including an inventory of installed software applications, system and process performance, resource utilization, and network dependencies between workloads. The information collected by agents is secured at rest and in transit to the Application Discovery Service database in the cloud. </p> </li> </ul> <p>We recommend that you use agent-based discovery for non-VMware environments and to collect information about software and software dependencies. You can also run agent-based and agentless discovery simultaneously. Use agentless discovery to quickly complete the initial infrastructure assessment and then install agents on select hosts.</p> <p>Application Discovery Service integrates with application discovery solutions from AWS Partner Network (APN) partners. Third-party application discovery tools can query Application Discovery Service and write to the Application Discovery Service database using a public API. You can then import the data into either a visualization tool or cloud-migration solution.</p> <important> <p>Application Discovery Service doesn't gather sensitive information. All data is handled according to the <a href="http://aws.amazon.com/privacy/">AWS Privacy Policy</a>. You can operate Application Discovery Service offline to inspect collected data before it is shared with the service.</p> </important> <p>This API reference provides descriptions, syntax, and usage examples for each of the actions and data types for Application Discovery Service. The topic for each action shows the API request parameters and the response. Alternatively, you can use one of the AWS SDKs to access an API that is tailored to the programming language or platform that you're using. For more information, see <a href="http://aws.amazon.com/tools/#SDKs">AWS SDKs</a>.</p> <p>This guide is intended for use with the <a href="http://docs.aws.amazon.com/application-discovery/latest/userguide/"> <i>AWS Application Discovery Service User Guide</i> </a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/discovery/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "discovery.ap-northeast-1.amazonaws.com", "ap-southeast-1": "discovery.ap-southeast-1.amazonaws.com",
                           "us-west-2": "discovery.us-west-2.amazonaws.com",
                           "eu-west-2": "discovery.eu-west-2.amazonaws.com", "ap-northeast-3": "discovery.ap-northeast-3.amazonaws.com", "eu-central-1": "discovery.eu-central-1.amazonaws.com",
                           "us-east-2": "discovery.us-east-2.amazonaws.com",
                           "us-east-1": "discovery.us-east-1.amazonaws.com", "cn-northwest-1": "discovery.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "discovery.ap-south-1.amazonaws.com",
                           "eu-north-1": "discovery.eu-north-1.amazonaws.com", "ap-northeast-2": "discovery.ap-northeast-2.amazonaws.com",
                           "us-west-1": "discovery.us-west-1.amazonaws.com", "us-gov-east-1": "discovery.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "discovery.eu-west-3.amazonaws.com", "cn-north-1": "discovery.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "discovery.sa-east-1.amazonaws.com",
                           "eu-west-1": "discovery.eu-west-1.amazonaws.com", "us-gov-west-1": "discovery.us-gov-west-1.amazonaws.com", "ap-southeast-2": "discovery.ap-southeast-2.amazonaws.com", "ca-central-1": "discovery.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "discovery.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "discovery.ap-southeast-1.amazonaws.com",
      "us-west-2": "discovery.us-west-2.amazonaws.com",
      "eu-west-2": "discovery.eu-west-2.amazonaws.com",
      "ap-northeast-3": "discovery.ap-northeast-3.amazonaws.com",
      "eu-central-1": "discovery.eu-central-1.amazonaws.com",
      "us-east-2": "discovery.us-east-2.amazonaws.com",
      "us-east-1": "discovery.us-east-1.amazonaws.com",
      "cn-northwest-1": "discovery.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "discovery.ap-south-1.amazonaws.com",
      "eu-north-1": "discovery.eu-north-1.amazonaws.com",
      "ap-northeast-2": "discovery.ap-northeast-2.amazonaws.com",
      "us-west-1": "discovery.us-west-1.amazonaws.com",
      "us-gov-east-1": "discovery.us-gov-east-1.amazonaws.com",
      "eu-west-3": "discovery.eu-west-3.amazonaws.com",
      "cn-north-1": "discovery.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "discovery.sa-east-1.amazonaws.com",
      "eu-west-1": "discovery.eu-west-1.amazonaws.com",
      "us-gov-west-1": "discovery.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "discovery.ap-southeast-2.amazonaws.com",
      "ca-central-1": "discovery.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "discovery"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociateConfigurationItemsToApplication_600768 = ref object of OpenApiRestCall_600426
proc url_AssociateConfigurationItemsToApplication_600770(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AssociateConfigurationItemsToApplication_600769(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates one or more configuration items with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.AssociateConfigurationItemsToApplication"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_AssociateConfigurationItemsToApplication_600768;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates one or more configuration items with an application.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_AssociateConfigurationItemsToApplication_600768;
          body: JsonNode): Recallable =
  ## associateConfigurationItemsToApplication
  ## Associates one or more configuration items with an application.
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var associateConfigurationItemsToApplication* = Call_AssociateConfigurationItemsToApplication_600768(
    name: "associateConfigurationItemsToApplication", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.AssociateConfigurationItemsToApplication",
    validator: validate_AssociateConfigurationItemsToApplication_600769,
    base: "/", url: url_AssociateConfigurationItemsToApplication_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImportData_601037 = ref object of OpenApiRestCall_600426
proc url_BatchDeleteImportData_601039(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDeleteImportData_601038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.BatchDeleteImportData"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_BatchDeleteImportData_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_BatchDeleteImportData_601037; body: JsonNode): Recallable =
  ## batchDeleteImportData
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var batchDeleteImportData* = Call_BatchDeleteImportData_601037(
    name: "batchDeleteImportData", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.BatchDeleteImportData",
    validator: validate_BatchDeleteImportData_601038, base: "/",
    url: url_BatchDeleteImportData_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplication_601052 = ref object of OpenApiRestCall_600426
proc url_CreateApplication_601054(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApplication_601053(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an application with the given name and description.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.CreateApplication"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_CreateApplication_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application with the given name and description.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_CreateApplication_601052; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application with the given name and description.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var createApplication* = Call_CreateApplication_601052(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.CreateApplication",
    validator: validate_CreateApplication_601053, base: "/",
    url: url_CreateApplication_601054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_601067 = ref object of OpenApiRestCall_600426
proc url_CreateTags_601069(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTags_601068(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.CreateTags"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CreateTags_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CreateTags_601067; body: JsonNode): Recallable =
  ## createTags
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var createTags* = Call_CreateTags_601067(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.CreateTags",
                                      validator: validate_CreateTags_601068,
                                      base: "/", url: url_CreateTags_601069,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplications_601082 = ref object of OpenApiRestCall_600426
proc url_DeleteApplications_601084(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteApplications_601083(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a list of applications and their associations with configuration items.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DeleteApplications"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_DeleteApplications_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of applications and their associations with configuration items.
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_DeleteApplications_601082; body: JsonNode): Recallable =
  ## deleteApplications
  ## Deletes a list of applications and their associations with configuration items.
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var deleteApplications* = Call_DeleteApplications_601082(
    name: "deleteApplications", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DeleteApplications",
    validator: validate_DeleteApplications_601083, base: "/",
    url: url_DeleteApplications_601084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_601097 = ref object of OpenApiRestCall_600426
proc url_DeleteTags_601099(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTags_601098(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DeleteTags"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_DeleteTags_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_DeleteTags_601097; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var deleteTags* = Call_DeleteTags_601097(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DeleteTags",
                                      validator: validate_DeleteTags_601098,
                                      base: "/", url: url_DeleteTags_601099,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAgents_601112 = ref object of OpenApiRestCall_600426
proc url_DescribeAgents_601114(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAgents_601113(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeAgents"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_DescribeAgents_601112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DescribeAgents_601112; body: JsonNode): Recallable =
  ## describeAgents
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var describeAgents* = Call_DescribeAgents_601112(name: "describeAgents",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeAgents",
    validator: validate_DescribeAgents_601113, base: "/", url: url_DescribeAgents_601114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurations_601127 = ref object of OpenApiRestCall_600426
proc url_DescribeConfigurations_601129(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeConfigurations_601128(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="http://docs.aws.amazon.com/application-discovery/latest/APIReference/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeConfigurations"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_DescribeConfigurations_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="http://docs.aws.amazon.com/application-discovery/latest/APIReference/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a>.</p> </note>
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DescribeConfigurations_601127; body: JsonNode): Recallable =
  ## describeConfigurations
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="http://docs.aws.amazon.com/application-discovery/latest/APIReference/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a>.</p> </note>
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var describeConfigurations* = Call_DescribeConfigurations_601127(
    name: "describeConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeConfigurations",
    validator: validate_DescribeConfigurations_601128, base: "/",
    url: url_DescribeConfigurations_601129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContinuousExports_601142 = ref object of OpenApiRestCall_600426
proc url_DescribeContinuousExports_601144(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeContinuousExports_601143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601145 = query.getOrDefault("maxResults")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "maxResults", valid_601145
  var valid_601146 = query.getOrDefault("nextToken")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "nextToken", valid_601146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601147 = header.getOrDefault("X-Amz-Date")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Date", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Security-Token")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Security-Token", valid_601148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601149 = header.getOrDefault("X-Amz-Target")
  valid_601149 = validateParameter(valid_601149, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeContinuousExports"))
  if valid_601149 != nil:
    section.add "X-Amz-Target", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Content-Sha256", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Algorithm")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Algorithm", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Signature", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-SignedHeaders", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Credential")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Credential", valid_601154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601156: Call_DescribeContinuousExports_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ## 
  let valid = call_601156.validator(path, query, header, formData, body)
  let scheme = call_601156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601156.url(scheme.get, call_601156.host, call_601156.base,
                         call_601156.route, valid.getOrDefault("path"))
  result = hook(call_601156, url, valid)

proc call*(call_601157: Call_DescribeContinuousExports_601142; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeContinuousExports
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601158 = newJObject()
  var body_601159 = newJObject()
  add(query_601158, "maxResults", newJString(maxResults))
  add(query_601158, "nextToken", newJString(nextToken))
  if body != nil:
    body_601159 = body
  result = call_601157.call(nil, query_601158, nil, nil, body_601159)

var describeContinuousExports* = Call_DescribeContinuousExports_601142(
    name: "describeContinuousExports", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeContinuousExports",
    validator: validate_DescribeContinuousExports_601143, base: "/",
    url: url_DescribeContinuousExports_601144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportConfigurations_601161 = ref object of OpenApiRestCall_600426
proc url_DescribeExportConfigurations_601163(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeExportConfigurations_601162(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601164 = header.getOrDefault("X-Amz-Date")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Date", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Security-Token")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Security-Token", valid_601165
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601166 = header.getOrDefault("X-Amz-Target")
  valid_601166 = validateParameter(valid_601166, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeExportConfigurations"))
  if valid_601166 != nil:
    section.add "X-Amz-Target", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Content-Sha256", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Algorithm")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Algorithm", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Signature")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Signature", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-SignedHeaders", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Credential")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Credential", valid_601171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601173: Call_DescribeExportConfigurations_601161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ## 
  let valid = call_601173.validator(path, query, header, formData, body)
  let scheme = call_601173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601173.url(scheme.get, call_601173.host, call_601173.base,
                         call_601173.route, valid.getOrDefault("path"))
  result = hook(call_601173, url, valid)

proc call*(call_601174: Call_DescribeExportConfigurations_601161; body: JsonNode): Recallable =
  ## describeExportConfigurations
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ##   body: JObject (required)
  var body_601175 = newJObject()
  if body != nil:
    body_601175 = body
  result = call_601174.call(nil, nil, nil, nil, body_601175)

var describeExportConfigurations* = Call_DescribeExportConfigurations_601161(
    name: "describeExportConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeExportConfigurations",
    validator: validate_DescribeExportConfigurations_601162, base: "/",
    url: url_DescribeExportConfigurations_601163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportTasks_601176 = ref object of OpenApiRestCall_600426
proc url_DescribeExportTasks_601178(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeExportTasks_601177(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601179 = header.getOrDefault("X-Amz-Date")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Date", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Security-Token")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Security-Token", valid_601180
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601181 = header.getOrDefault("X-Amz-Target")
  valid_601181 = validateParameter(valid_601181, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeExportTasks"))
  if valid_601181 != nil:
    section.add "X-Amz-Target", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601188: Call_DescribeExportTasks_601176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ## 
  let valid = call_601188.validator(path, query, header, formData, body)
  let scheme = call_601188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601188.url(scheme.get, call_601188.host, call_601188.base,
                         call_601188.route, valid.getOrDefault("path"))
  result = hook(call_601188, url, valid)

proc call*(call_601189: Call_DescribeExportTasks_601176; body: JsonNode): Recallable =
  ## describeExportTasks
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ##   body: JObject (required)
  var body_601190 = newJObject()
  if body != nil:
    body_601190 = body
  result = call_601189.call(nil, nil, nil, nil, body_601190)

var describeExportTasks* = Call_DescribeExportTasks_601176(
    name: "describeExportTasks", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeExportTasks",
    validator: validate_DescribeExportTasks_601177, base: "/",
    url: url_DescribeExportTasks_601178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImportTasks_601191 = ref object of OpenApiRestCall_600426
proc url_DescribeImportTasks_601193(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeImportTasks_601192(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601194 = query.getOrDefault("maxResults")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "maxResults", valid_601194
  var valid_601195 = query.getOrDefault("nextToken")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "nextToken", valid_601195
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601196 = header.getOrDefault("X-Amz-Date")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Date", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Security-Token")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Security-Token", valid_601197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601198 = header.getOrDefault("X-Amz-Target")
  valid_601198 = validateParameter(valid_601198, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeImportTasks"))
  if valid_601198 != nil:
    section.add "X-Amz-Target", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601205: Call_DescribeImportTasks_601191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ## 
  let valid = call_601205.validator(path, query, header, formData, body)
  let scheme = call_601205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601205.url(scheme.get, call_601205.host, call_601205.base,
                         call_601205.route, valid.getOrDefault("path"))
  result = hook(call_601205, url, valid)

proc call*(call_601206: Call_DescribeImportTasks_601191; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeImportTasks
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601207 = newJObject()
  var body_601208 = newJObject()
  add(query_601207, "maxResults", newJString(maxResults))
  add(query_601207, "nextToken", newJString(nextToken))
  if body != nil:
    body_601208 = body
  result = call_601206.call(nil, query_601207, nil, nil, body_601208)

var describeImportTasks* = Call_DescribeImportTasks_601191(
    name: "describeImportTasks", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeImportTasks",
    validator: validate_DescribeImportTasks_601192, base: "/",
    url: url_DescribeImportTasks_601193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_601209 = ref object of OpenApiRestCall_600426
proc url_DescribeTags_601211(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTags_601210(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601212 = header.getOrDefault("X-Amz-Date")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Date", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Security-Token")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Security-Token", valid_601213
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601214 = header.getOrDefault("X-Amz-Target")
  valid_601214 = validateParameter(valid_601214, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeTags"))
  if valid_601214 != nil:
    section.add "X-Amz-Target", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Content-Sha256", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Algorithm")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Algorithm", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Signature")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Signature", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-SignedHeaders", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Credential")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Credential", valid_601219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601221: Call_DescribeTags_601209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ## 
  let valid = call_601221.validator(path, query, header, formData, body)
  let scheme = call_601221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601221.url(scheme.get, call_601221.host, call_601221.base,
                         call_601221.route, valid.getOrDefault("path"))
  result = hook(call_601221, url, valid)

proc call*(call_601222: Call_DescribeTags_601209; body: JsonNode): Recallable =
  ## describeTags
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ##   body: JObject (required)
  var body_601223 = newJObject()
  if body != nil:
    body_601223 = body
  result = call_601222.call(nil, nil, nil, nil, body_601223)

var describeTags* = Call_DescribeTags_601209(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeTags",
    validator: validate_DescribeTags_601210, base: "/", url: url_DescribeTags_601211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConfigurationItemsFromApplication_601224 = ref object of OpenApiRestCall_600426
proc url_DisassociateConfigurationItemsFromApplication_601226(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateConfigurationItemsFromApplication_601225(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Disassociates one or more configuration items from an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601227 = header.getOrDefault("X-Amz-Date")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Date", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Security-Token")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Security-Token", valid_601228
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601229 = header.getOrDefault("X-Amz-Target")
  valid_601229 = validateParameter(valid_601229, JString, required = true, default = newJString("AWSPoseidonService_V2015_11_01.DisassociateConfigurationItemsFromApplication"))
  if valid_601229 != nil:
    section.add "X-Amz-Target", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Content-Sha256", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Algorithm")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Algorithm", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Signature")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Signature", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-SignedHeaders", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Credential")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Credential", valid_601234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601236: Call_DisassociateConfigurationItemsFromApplication_601224;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates one or more configuration items from an application.
  ## 
  let valid = call_601236.validator(path, query, header, formData, body)
  let scheme = call_601236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601236.url(scheme.get, call_601236.host, call_601236.base,
                         call_601236.route, valid.getOrDefault("path"))
  result = hook(call_601236, url, valid)

proc call*(call_601237: Call_DisassociateConfigurationItemsFromApplication_601224;
          body: JsonNode): Recallable =
  ## disassociateConfigurationItemsFromApplication
  ## Disassociates one or more configuration items from an application.
  ##   body: JObject (required)
  var body_601238 = newJObject()
  if body != nil:
    body_601238 = body
  result = call_601237.call(nil, nil, nil, nil, body_601238)

var disassociateConfigurationItemsFromApplication* = Call_DisassociateConfigurationItemsFromApplication_601224(
    name: "disassociateConfigurationItemsFromApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DisassociateConfigurationItemsFromApplication",
    validator: validate_DisassociateConfigurationItemsFromApplication_601225,
    base: "/", url: url_DisassociateConfigurationItemsFromApplication_601226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportConfigurations_601239 = ref object of OpenApiRestCall_600426
proc url_ExportConfigurations_601241(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ExportConfigurations_601240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601242 = header.getOrDefault("X-Amz-Date")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Date", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Security-Token")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Security-Token", valid_601243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601244 = header.getOrDefault("X-Amz-Target")
  valid_601244 = validateParameter(valid_601244, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ExportConfigurations"))
  if valid_601244 != nil:
    section.add "X-Amz-Target", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Content-Sha256", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Algorithm")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Algorithm", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Signature")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Signature", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-SignedHeaders", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Credential")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Credential", valid_601249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601250: Call_ExportConfigurations_601239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  ## 
  let valid = call_601250.validator(path, query, header, formData, body)
  let scheme = call_601250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601250.url(scheme.get, call_601250.host, call_601250.base,
                         call_601250.route, valid.getOrDefault("path"))
  result = hook(call_601250, url, valid)

proc call*(call_601251: Call_ExportConfigurations_601239): Recallable =
  ## exportConfigurations
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  result = call_601251.call(nil, nil, nil, nil, nil)

var exportConfigurations* = Call_ExportConfigurations_601239(
    name: "exportConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ExportConfigurations",
    validator: validate_ExportConfigurations_601240, base: "/",
    url: url_ExportConfigurations_601241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoverySummary_601252 = ref object of OpenApiRestCall_600426
proc url_GetDiscoverySummary_601254(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDiscoverySummary_601253(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601255 = header.getOrDefault("X-Amz-Date")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Date", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Security-Token")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Security-Token", valid_601256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601257 = header.getOrDefault("X-Amz-Target")
  valid_601257 = validateParameter(valid_601257, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.GetDiscoverySummary"))
  if valid_601257 != nil:
    section.add "X-Amz-Target", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Content-Sha256", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Algorithm")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Algorithm", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Signature")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Signature", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-SignedHeaders", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Credential")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Credential", valid_601262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601264: Call_GetDiscoverySummary_601252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ## 
  let valid = call_601264.validator(path, query, header, formData, body)
  let scheme = call_601264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601264.url(scheme.get, call_601264.host, call_601264.base,
                         call_601264.route, valid.getOrDefault("path"))
  result = hook(call_601264, url, valid)

proc call*(call_601265: Call_GetDiscoverySummary_601252; body: JsonNode): Recallable =
  ## getDiscoverySummary
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ##   body: JObject (required)
  var body_601266 = newJObject()
  if body != nil:
    body_601266 = body
  result = call_601265.call(nil, nil, nil, nil, body_601266)

var getDiscoverySummary* = Call_GetDiscoverySummary_601252(
    name: "getDiscoverySummary", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.GetDiscoverySummary",
    validator: validate_GetDiscoverySummary_601253, base: "/",
    url: url_GetDiscoverySummary_601254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_601267 = ref object of OpenApiRestCall_600426
proc url_ListConfigurations_601269(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListConfigurations_601268(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves a list of configuration items as specified by the value passed to the required paramater <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601270 = header.getOrDefault("X-Amz-Date")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Date", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Security-Token")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Security-Token", valid_601271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601272 = header.getOrDefault("X-Amz-Target")
  valid_601272 = validateParameter(valid_601272, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ListConfigurations"))
  if valid_601272 != nil:
    section.add "X-Amz-Target", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Content-Sha256", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Algorithm")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Algorithm", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Signature")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Signature", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-SignedHeaders", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Credential")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Credential", valid_601277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601279: Call_ListConfigurations_601267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of configuration items as specified by the value passed to the required paramater <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ## 
  let valid = call_601279.validator(path, query, header, formData, body)
  let scheme = call_601279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601279.url(scheme.get, call_601279.host, call_601279.base,
                         call_601279.route, valid.getOrDefault("path"))
  result = hook(call_601279, url, valid)

proc call*(call_601280: Call_ListConfigurations_601267; body: JsonNode): Recallable =
  ## listConfigurations
  ## Retrieves a list of configuration items as specified by the value passed to the required paramater <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ##   body: JObject (required)
  var body_601281 = newJObject()
  if body != nil:
    body_601281 = body
  result = call_601280.call(nil, nil, nil, nil, body_601281)

var listConfigurations* = Call_ListConfigurations_601267(
    name: "listConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ListConfigurations",
    validator: validate_ListConfigurations_601268, base: "/",
    url: url_ListConfigurations_601269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServerNeighbors_601282 = ref object of OpenApiRestCall_600426
proc url_ListServerNeighbors_601284(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListServerNeighbors_601283(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601285 = header.getOrDefault("X-Amz-Date")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Date", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Security-Token")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Security-Token", valid_601286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601287 = header.getOrDefault("X-Amz-Target")
  valid_601287 = validateParameter(valid_601287, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ListServerNeighbors"))
  if valid_601287 != nil:
    section.add "X-Amz-Target", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Content-Sha256", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Algorithm")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Algorithm", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Signature")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Signature", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-SignedHeaders", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Credential")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Credential", valid_601292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601294: Call_ListServerNeighbors_601282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ## 
  let valid = call_601294.validator(path, query, header, formData, body)
  let scheme = call_601294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601294.url(scheme.get, call_601294.host, call_601294.base,
                         call_601294.route, valid.getOrDefault("path"))
  result = hook(call_601294, url, valid)

proc call*(call_601295: Call_ListServerNeighbors_601282; body: JsonNode): Recallable =
  ## listServerNeighbors
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ##   body: JObject (required)
  var body_601296 = newJObject()
  if body != nil:
    body_601296 = body
  result = call_601295.call(nil, nil, nil, nil, body_601296)

var listServerNeighbors* = Call_ListServerNeighbors_601282(
    name: "listServerNeighbors", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ListServerNeighbors",
    validator: validate_ListServerNeighbors_601283, base: "/",
    url: url_ListServerNeighbors_601284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartContinuousExport_601297 = ref object of OpenApiRestCall_600426
proc url_StartContinuousExport_601299(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartContinuousExport_601298(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601300 = header.getOrDefault("X-Amz-Date")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Date", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Security-Token")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Security-Token", valid_601301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601302 = header.getOrDefault("X-Amz-Target")
  valid_601302 = validateParameter(valid_601302, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartContinuousExport"))
  if valid_601302 != nil:
    section.add "X-Amz-Target", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Content-Sha256", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Algorithm")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Algorithm", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Signature")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Signature", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-SignedHeaders", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Credential")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Credential", valid_601307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601309: Call_StartContinuousExport_601297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  let valid = call_601309.validator(path, query, header, formData, body)
  let scheme = call_601309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601309.url(scheme.get, call_601309.host, call_601309.base,
                         call_601309.route, valid.getOrDefault("path"))
  result = hook(call_601309, url, valid)

proc call*(call_601310: Call_StartContinuousExport_601297; body: JsonNode): Recallable =
  ## startContinuousExport
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ##   body: JObject (required)
  var body_601311 = newJObject()
  if body != nil:
    body_601311 = body
  result = call_601310.call(nil, nil, nil, nil, body_601311)

var startContinuousExport* = Call_StartContinuousExport_601297(
    name: "startContinuousExport", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartContinuousExport",
    validator: validate_StartContinuousExport_601298, base: "/",
    url: url_StartContinuousExport_601299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDataCollectionByAgentIds_601312 = ref object of OpenApiRestCall_600426
proc url_StartDataCollectionByAgentIds_601314(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartDataCollectionByAgentIds_601313(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Instructs the specified agents or connectors to start collecting data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601315 = header.getOrDefault("X-Amz-Date")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Date", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Security-Token")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Security-Token", valid_601316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601317 = header.getOrDefault("X-Amz-Target")
  valid_601317 = validateParameter(valid_601317, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartDataCollectionByAgentIds"))
  if valid_601317 != nil:
    section.add "X-Amz-Target", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Content-Sha256", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Algorithm")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Algorithm", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Signature")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Signature", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-SignedHeaders", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Credential")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Credential", valid_601322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601324: Call_StartDataCollectionByAgentIds_601312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instructs the specified agents or connectors to start collecting data.
  ## 
  let valid = call_601324.validator(path, query, header, formData, body)
  let scheme = call_601324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601324.url(scheme.get, call_601324.host, call_601324.base,
                         call_601324.route, valid.getOrDefault("path"))
  result = hook(call_601324, url, valid)

proc call*(call_601325: Call_StartDataCollectionByAgentIds_601312; body: JsonNode): Recallable =
  ## startDataCollectionByAgentIds
  ## Instructs the specified agents or connectors to start collecting data.
  ##   body: JObject (required)
  var body_601326 = newJObject()
  if body != nil:
    body_601326 = body
  result = call_601325.call(nil, nil, nil, nil, body_601326)

var startDataCollectionByAgentIds* = Call_StartDataCollectionByAgentIds_601312(
    name: "startDataCollectionByAgentIds", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartDataCollectionByAgentIds",
    validator: validate_StartDataCollectionByAgentIds_601313, base: "/",
    url: url_StartDataCollectionByAgentIds_601314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportTask_601327 = ref object of OpenApiRestCall_600426
proc url_StartExportTask_601329(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartExportTask_601328(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601330 = header.getOrDefault("X-Amz-Date")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Date", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Security-Token")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Security-Token", valid_601331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601332 = header.getOrDefault("X-Amz-Target")
  valid_601332 = validateParameter(valid_601332, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartExportTask"))
  if valid_601332 != nil:
    section.add "X-Amz-Target", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Content-Sha256", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Algorithm")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Algorithm", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Signature")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Signature", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-SignedHeaders", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Credential")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Credential", valid_601337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601339: Call_StartExportTask_601327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ## 
  let valid = call_601339.validator(path, query, header, formData, body)
  let scheme = call_601339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601339.url(scheme.get, call_601339.host, call_601339.base,
                         call_601339.route, valid.getOrDefault("path"))
  result = hook(call_601339, url, valid)

proc call*(call_601340: Call_StartExportTask_601327; body: JsonNode): Recallable =
  ## startExportTask
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ##   body: JObject (required)
  var body_601341 = newJObject()
  if body != nil:
    body_601341 = body
  result = call_601340.call(nil, nil, nil, nil, body_601341)

var startExportTask* = Call_StartExportTask_601327(name: "startExportTask",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartExportTask",
    validator: validate_StartExportTask_601328, base: "/", url: url_StartExportTask_601329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportTask_601342 = ref object of OpenApiRestCall_600426
proc url_StartImportTask_601344(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartImportTask_601343(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601345 = header.getOrDefault("X-Amz-Date")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Date", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Security-Token")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Security-Token", valid_601346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601347 = header.getOrDefault("X-Amz-Target")
  valid_601347 = validateParameter(valid_601347, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartImportTask"))
  if valid_601347 != nil:
    section.add "X-Amz-Target", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Content-Sha256", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Algorithm")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Algorithm", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Signature")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Signature", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-SignedHeaders", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Credential")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Credential", valid_601352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601354: Call_StartImportTask_601342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  let valid = call_601354.validator(path, query, header, formData, body)
  let scheme = call_601354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601354.url(scheme.get, call_601354.host, call_601354.base,
                         call_601354.route, valid.getOrDefault("path"))
  result = hook(call_601354, url, valid)

proc call*(call_601355: Call_StartImportTask_601342; body: JsonNode): Recallable =
  ## startImportTask
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_601356 = newJObject()
  if body != nil:
    body_601356 = body
  result = call_601355.call(nil, nil, nil, nil, body_601356)

var startImportTask* = Call_StartImportTask_601342(name: "startImportTask",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartImportTask",
    validator: validate_StartImportTask_601343, base: "/", url: url_StartImportTask_601344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContinuousExport_601357 = ref object of OpenApiRestCall_600426
proc url_StopContinuousExport_601359(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopContinuousExport_601358(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601360 = header.getOrDefault("X-Amz-Date")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Date", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Security-Token")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Security-Token", valid_601361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601362 = header.getOrDefault("X-Amz-Target")
  valid_601362 = validateParameter(valid_601362, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StopContinuousExport"))
  if valid_601362 != nil:
    section.add "X-Amz-Target", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Content-Sha256", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Algorithm")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Algorithm", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Signature")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Signature", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-SignedHeaders", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Credential")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Credential", valid_601367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601369: Call_StopContinuousExport_601357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  let valid = call_601369.validator(path, query, header, formData, body)
  let scheme = call_601369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601369.url(scheme.get, call_601369.host, call_601369.base,
                         call_601369.route, valid.getOrDefault("path"))
  result = hook(call_601369, url, valid)

proc call*(call_601370: Call_StopContinuousExport_601357; body: JsonNode): Recallable =
  ## stopContinuousExport
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ##   body: JObject (required)
  var body_601371 = newJObject()
  if body != nil:
    body_601371 = body
  result = call_601370.call(nil, nil, nil, nil, body_601371)

var stopContinuousExport* = Call_StopContinuousExport_601357(
    name: "stopContinuousExport", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StopContinuousExport",
    validator: validate_StopContinuousExport_601358, base: "/",
    url: url_StopContinuousExport_601359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDataCollectionByAgentIds_601372 = ref object of OpenApiRestCall_600426
proc url_StopDataCollectionByAgentIds_601374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopDataCollectionByAgentIds_601373(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Instructs the specified agents or connectors to stop collecting data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601375 = header.getOrDefault("X-Amz-Date")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Date", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Security-Token")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Security-Token", valid_601376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601377 = header.getOrDefault("X-Amz-Target")
  valid_601377 = validateParameter(valid_601377, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StopDataCollectionByAgentIds"))
  if valid_601377 != nil:
    section.add "X-Amz-Target", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Content-Sha256", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Algorithm")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Algorithm", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Signature")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Signature", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-SignedHeaders", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Credential")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Credential", valid_601382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601384: Call_StopDataCollectionByAgentIds_601372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instructs the specified agents or connectors to stop collecting data.
  ## 
  let valid = call_601384.validator(path, query, header, formData, body)
  let scheme = call_601384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601384.url(scheme.get, call_601384.host, call_601384.base,
                         call_601384.route, valid.getOrDefault("path"))
  result = hook(call_601384, url, valid)

proc call*(call_601385: Call_StopDataCollectionByAgentIds_601372; body: JsonNode): Recallable =
  ## stopDataCollectionByAgentIds
  ## Instructs the specified agents or connectors to stop collecting data.
  ##   body: JObject (required)
  var body_601386 = newJObject()
  if body != nil:
    body_601386 = body
  result = call_601385.call(nil, nil, nil, nil, body_601386)

var stopDataCollectionByAgentIds* = Call_StopDataCollectionByAgentIds_601372(
    name: "stopDataCollectionByAgentIds", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StopDataCollectionByAgentIds",
    validator: validate_StopDataCollectionByAgentIds_601373, base: "/",
    url: url_StopDataCollectionByAgentIds_601374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_601387 = ref object of OpenApiRestCall_600426
proc url_UpdateApplication_601389(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateApplication_601388(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates metadata about an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601390 = header.getOrDefault("X-Amz-Date")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Date", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Security-Token")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Security-Token", valid_601391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601392 = header.getOrDefault("X-Amz-Target")
  valid_601392 = validateParameter(valid_601392, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.UpdateApplication"))
  if valid_601392 != nil:
    section.add "X-Amz-Target", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Content-Sha256", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Algorithm")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Algorithm", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Signature")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Signature", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-SignedHeaders", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Credential")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Credential", valid_601397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601399: Call_UpdateApplication_601387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates metadata about an application.
  ## 
  let valid = call_601399.validator(path, query, header, formData, body)
  let scheme = call_601399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601399.url(scheme.get, call_601399.host, call_601399.base,
                         call_601399.route, valid.getOrDefault("path"))
  result = hook(call_601399, url, valid)

proc call*(call_601400: Call_UpdateApplication_601387; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates metadata about an application.
  ##   body: JObject (required)
  var body_601401 = newJObject()
  if body != nil:
    body_601401 = body
  result = call_601400.call(nil, nil, nil, nil, body_601401)

var updateApplication* = Call_UpdateApplication_601387(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.UpdateApplication",
    validator: validate_UpdateApplication_601388, base: "/",
    url: url_UpdateApplication_601389, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
