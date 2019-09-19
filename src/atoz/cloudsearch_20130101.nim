
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2013-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the Amazon CloudSearch configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region" target="_blank">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudsearch/
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
                           "us-east-1": "cloudsearch.us-east-1.amazonaws.com", "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com", "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudsearch.us-west-1.amazonaws.com", "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com", "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
      "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
      "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
      "us-east-1": "cloudsearch.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudsearch.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudsearch"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostBuildSuggesters_773204 = ref object of OpenApiRestCall_772597
proc url_PostBuildSuggesters_773206(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostBuildSuggesters_773205(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773207 = query.getOrDefault("Action")
  valid_773207 = validateParameter(valid_773207, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_773207 != nil:
    section.add "Action", valid_773207
  var valid_773208 = query.getOrDefault("Version")
  valid_773208 = validateParameter(valid_773208, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773208 != nil:
    section.add "Version", valid_773208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773209 = header.getOrDefault("X-Amz-Date")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Date", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Security-Token")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Security-Token", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Content-Sha256", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Algorithm")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Algorithm", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Signature")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Signature", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-SignedHeaders", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Credential")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Credential", valid_773215
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773216 = formData.getOrDefault("DomainName")
  valid_773216 = validateParameter(valid_773216, JString, required = true,
                                 default = nil)
  if valid_773216 != nil:
    section.add "DomainName", valid_773216
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773217: Call_PostBuildSuggesters_773204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773217.validator(path, query, header, formData, body)
  let scheme = call_773217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773217.url(scheme.get, call_773217.host, call_773217.base,
                         call_773217.route, valid.getOrDefault("path"))
  result = hook(call_773217, url, valid)

proc call*(call_773218: Call_PostBuildSuggesters_773204; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## postBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773219 = newJObject()
  var formData_773220 = newJObject()
  add(formData_773220, "DomainName", newJString(DomainName))
  add(query_773219, "Action", newJString(Action))
  add(query_773219, "Version", newJString(Version))
  result = call_773218.call(nil, query_773219, nil, formData_773220, nil)

var postBuildSuggesters* = Call_PostBuildSuggesters_773204(
    name: "postBuildSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_PostBuildSuggesters_773205, base: "/",
    url: url_PostBuildSuggesters_773206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuildSuggesters_772933 = ref object of OpenApiRestCall_772597
proc url_GetBuildSuggesters_772935(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetBuildSuggesters_772934(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773060 = query.getOrDefault("Action")
  valid_773060 = validateParameter(valid_773060, JString, required = true,
                                 default = newJString("BuildSuggesters"))
  if valid_773060 != nil:
    section.add "Action", valid_773060
  var valid_773061 = query.getOrDefault("DomainName")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "DomainName", valid_773061
  var valid_773062 = query.getOrDefault("Version")
  valid_773062 = validateParameter(valid_773062, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773062 != nil:
    section.add "Version", valid_773062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773063 = header.getOrDefault("X-Amz-Date")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Date", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Security-Token")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Security-Token", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Content-Sha256", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Algorithm")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Algorithm", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Signature")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Signature", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-SignedHeaders", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-Credential")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-Credential", valid_773069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773092: Call_GetBuildSuggesters_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773092.validator(path, query, header, formData, body)
  let scheme = call_773092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773092.url(scheme.get, call_773092.host, call_773092.base,
                         call_773092.route, valid.getOrDefault("path"))
  result = hook(call_773092, url, valid)

proc call*(call_773163: Call_GetBuildSuggesters_772933; DomainName: string;
          Action: string = "BuildSuggesters"; Version: string = "2013-01-01"): Recallable =
  ## getBuildSuggesters
  ## Indexes the search suggestions. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html#configuring-suggesters">Configuring Suggesters</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773164 = newJObject()
  add(query_773164, "Action", newJString(Action))
  add(query_773164, "DomainName", newJString(DomainName))
  add(query_773164, "Version", newJString(Version))
  result = call_773163.call(nil, query_773164, nil, nil, nil)

var getBuildSuggesters* = Call_GetBuildSuggesters_772933(
    name: "getBuildSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=BuildSuggesters",
    validator: validate_GetBuildSuggesters_772934, base: "/",
    url: url_GetBuildSuggesters_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDomain_773237 = ref object of OpenApiRestCall_772597
proc url_PostCreateDomain_773239(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDomain_773238(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773240 = query.getOrDefault("Action")
  valid_773240 = validateParameter(valid_773240, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_773240 != nil:
    section.add "Action", valid_773240
  var valid_773241 = query.getOrDefault("Version")
  valid_773241 = validateParameter(valid_773241, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773241 != nil:
    section.add "Version", valid_773241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773242 = header.getOrDefault("X-Amz-Date")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Date", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Security-Token")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Security-Token", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Content-Sha256", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-Algorithm")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Algorithm", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Signature")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Signature", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-SignedHeaders", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Credential")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Credential", valid_773248
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773249 = formData.getOrDefault("DomainName")
  valid_773249 = validateParameter(valid_773249, JString, required = true,
                                 default = nil)
  if valid_773249 != nil:
    section.add "DomainName", valid_773249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773250: Call_PostCreateDomain_773237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773250.validator(path, query, header, formData, body)
  let scheme = call_773250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773250.url(scheme.get, call_773250.host, call_773250.base,
                         call_773250.route, valid.getOrDefault("path"))
  result = hook(call_773250, url, valid)

proc call*(call_773251: Call_PostCreateDomain_773237; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773252 = newJObject()
  var formData_773253 = newJObject()
  add(formData_773253, "DomainName", newJString(DomainName))
  add(query_773252, "Action", newJString(Action))
  add(query_773252, "Version", newJString(Version))
  result = call_773251.call(nil, query_773252, nil, formData_773253, nil)

var postCreateDomain* = Call_PostCreateDomain_773237(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_773238,
    base: "/", url: url_PostCreateDomain_773239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_773221 = ref object of OpenApiRestCall_772597
proc url_GetCreateDomain_773223(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDomain_773222(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773224 = query.getOrDefault("Action")
  valid_773224 = validateParameter(valid_773224, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_773224 != nil:
    section.add "Action", valid_773224
  var valid_773225 = query.getOrDefault("DomainName")
  valid_773225 = validateParameter(valid_773225, JString, required = true,
                                 default = nil)
  if valid_773225 != nil:
    section.add "DomainName", valid_773225
  var valid_773226 = query.getOrDefault("Version")
  valid_773226 = validateParameter(valid_773226, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773226 != nil:
    section.add "Version", valid_773226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773227 = header.getOrDefault("X-Amz-Date")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Date", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Security-Token")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Security-Token", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Content-Sha256", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Algorithm")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Algorithm", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Signature")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Signature", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-SignedHeaders", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Credential")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Credential", valid_773233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773234: Call_GetCreateDomain_773221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773234.validator(path, query, header, formData, body)
  let scheme = call_773234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773234.url(scheme.get, call_773234.host, call_773234.base,
                         call_773234.route, valid.getOrDefault("path"))
  result = hook(call_773234, url, valid)

proc call*(call_773235: Call_GetCreateDomain_773221; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2013-01-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/creating-domains.html" target="_blank">Creating a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773236 = newJObject()
  add(query_773236, "Action", newJString(Action))
  add(query_773236, "DomainName", newJString(DomainName))
  add(query_773236, "Version", newJString(Version))
  result = call_773235.call(nil, query_773236, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_773221(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_773222,
    base: "/", url: url_GetCreateDomain_773223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineAnalysisScheme_773273 = ref object of OpenApiRestCall_772597
proc url_PostDefineAnalysisScheme_773275(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineAnalysisScheme_773274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773276 = query.getOrDefault("Action")
  valid_773276 = validateParameter(valid_773276, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_773276 != nil:
    section.add "Action", valid_773276
  var valid_773277 = query.getOrDefault("Version")
  valid_773277 = validateParameter(valid_773277, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773277 != nil:
    section.add "Version", valid_773277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773278 = header.getOrDefault("X-Amz-Date")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Date", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-Security-Token")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-Security-Token", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Content-Sha256", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Algorithm")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Algorithm", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Signature")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Signature", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-SignedHeaders", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Credential")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Credential", valid_773284
  result.add "header", section
  ## parameters in `formData` object:
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  section = newJObject()
  var valid_773285 = formData.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_773285
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773286 = formData.getOrDefault("DomainName")
  valid_773286 = validateParameter(valid_773286, JString, required = true,
                                 default = nil)
  if valid_773286 != nil:
    section.add "DomainName", valid_773286
  var valid_773287 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_773287
  var valid_773288 = formData.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_773288
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_PostDefineAnalysisScheme_773273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_PostDefineAnalysisScheme_773273; DomainName: string;
          AnalysisSchemeAnalysisOptions: string = "";
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisSchemeName: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   Version: string (required)
  var query_773291 = newJObject()
  var formData_773292 = newJObject()
  add(formData_773292, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  add(formData_773292, "DomainName", newJString(DomainName))
  add(formData_773292, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_773291, "Action", newJString(Action))
  add(formData_773292, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_773291, "Version", newJString(Version))
  result = call_773290.call(nil, query_773291, nil, formData_773292, nil)

var postDefineAnalysisScheme* = Call_PostDefineAnalysisScheme_773273(
    name: "postDefineAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_PostDefineAnalysisScheme_773274, base: "/",
    url: url_PostDefineAnalysisScheme_773275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineAnalysisScheme_773254 = ref object of OpenApiRestCall_772597
proc url_GetDefineAnalysisScheme_773256(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineAnalysisScheme_773255(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   AnalysisScheme.AnalysisSchemeLanguage: JString
  ##                                        : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisScheme.AnalysisSchemeName: JString
  ##                                    : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  ##   AnalysisScheme.AnalysisOptions: JString
  ##                                 : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773257 = query.getOrDefault("Action")
  valid_773257 = validateParameter(valid_773257, JString, required = true,
                                 default = newJString("DefineAnalysisScheme"))
  if valid_773257 != nil:
    section.add "Action", valid_773257
  var valid_773258 = query.getOrDefault("AnalysisScheme.AnalysisSchemeLanguage")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "AnalysisScheme.AnalysisSchemeLanguage", valid_773258
  var valid_773259 = query.getOrDefault("AnalysisScheme.AnalysisSchemeName")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "AnalysisScheme.AnalysisSchemeName", valid_773259
  var valid_773260 = query.getOrDefault("DomainName")
  valid_773260 = validateParameter(valid_773260, JString, required = true,
                                 default = nil)
  if valid_773260 != nil:
    section.add "DomainName", valid_773260
  var valid_773261 = query.getOrDefault("Version")
  valid_773261 = validateParameter(valid_773261, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773261 != nil:
    section.add "Version", valid_773261
  var valid_773262 = query.getOrDefault("AnalysisScheme.AnalysisOptions")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "AnalysisScheme.AnalysisOptions", valid_773262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773263 = header.getOrDefault("X-Amz-Date")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Date", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-Security-Token")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Security-Token", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Content-Sha256", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Algorithm")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Algorithm", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Signature")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Signature", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-SignedHeaders", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Credential")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Credential", valid_773269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773270: Call_GetDefineAnalysisScheme_773254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773270.validator(path, query, header, formData, body)
  let scheme = call_773270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773270.url(scheme.get, call_773270.host, call_773270.base,
                         call_773270.route, valid.getOrDefault("path"))
  result = hook(call_773270, url, valid)

proc call*(call_773271: Call_GetDefineAnalysisScheme_773254; DomainName: string;
          Action: string = "DefineAnalysisScheme";
          AnalysisSchemeAnalysisSchemeLanguage: string = "";
          AnalysisSchemeAnalysisSchemeName: string = "";
          Version: string = "2013-01-01"; AnalysisSchemeAnalysisOptions: string = ""): Recallable =
  ## getDefineAnalysisScheme
  ## Configures an analysis scheme that can be applied to a <code>text</code> or <code>text-array</code> field to define language-specific text processing options. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   AnalysisSchemeAnalysisSchemeLanguage: string
  ##                                       : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   AnalysisSchemeAnalysisSchemeName: string
  ##                                   : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  ##   AnalysisSchemeAnalysisOptions: string
  ##                                : Configuration information for an analysis scheme. Each analysis scheme has a unique name and specifies the language of the text to be processed. The following options can be configured for an analysis scheme: <code>Synonyms</code>, <code>Stopwords</code>, <code>StemmingDictionary</code>, <code>JapaneseTokenizationDictionary</code> and <code>AlgorithmicStemming</code>.
  ## 
  var query_773272 = newJObject()
  add(query_773272, "Action", newJString(Action))
  add(query_773272, "AnalysisScheme.AnalysisSchemeLanguage",
      newJString(AnalysisSchemeAnalysisSchemeLanguage))
  add(query_773272, "AnalysisScheme.AnalysisSchemeName",
      newJString(AnalysisSchemeAnalysisSchemeName))
  add(query_773272, "DomainName", newJString(DomainName))
  add(query_773272, "Version", newJString(Version))
  add(query_773272, "AnalysisScheme.AnalysisOptions",
      newJString(AnalysisSchemeAnalysisOptions))
  result = call_773271.call(nil, query_773272, nil, nil, nil)

var getDefineAnalysisScheme* = Call_GetDefineAnalysisScheme_773254(
    name: "getDefineAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineAnalysisScheme",
    validator: validate_GetDefineAnalysisScheme_773255, base: "/",
    url: url_GetDefineAnalysisScheme_773256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineExpression_773311 = ref object of OpenApiRestCall_772597
proc url_PostDefineExpression_773313(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineExpression_773312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773314 = query.getOrDefault("Action")
  valid_773314 = validateParameter(valid_773314, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_773314 != nil:
    section.add "Action", valid_773314
  var valid_773315 = query.getOrDefault("Version")
  valid_773315 = validateParameter(valid_773315, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773315 != nil:
    section.add "Version", valid_773315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773316 = header.getOrDefault("X-Amz-Date")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Date", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Security-Token")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Security-Token", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Content-Sha256", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-Algorithm")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-Algorithm", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Signature")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Signature", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-SignedHeaders", valid_773321
  var valid_773322 = header.getOrDefault("X-Amz-Credential")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Credential", valid_773322
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773323 = formData.getOrDefault("DomainName")
  valid_773323 = validateParameter(valid_773323, JString, required = true,
                                 default = nil)
  if valid_773323 != nil:
    section.add "DomainName", valid_773323
  var valid_773324 = formData.getOrDefault("Expression.ExpressionName")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "Expression.ExpressionName", valid_773324
  var valid_773325 = formData.getOrDefault("Expression.ExpressionValue")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "Expression.ExpressionValue", valid_773325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773326: Call_PostDefineExpression_773311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773326.validator(path, query, header, formData, body)
  let scheme = call_773326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773326.url(scheme.get, call_773326.host, call_773326.base,
                         call_773326.route, valid.getOrDefault("path"))
  result = hook(call_773326, url, valid)

proc call*(call_773327: Call_PostDefineExpression_773311; DomainName: string;
          ExpressionExpressionName: string = "";
          ExpressionExpressionValue: string = "";
          Action: string = "DefineExpression"; Version: string = "2013-01-01"): Recallable =
  ## postDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773328 = newJObject()
  var formData_773329 = newJObject()
  add(formData_773329, "DomainName", newJString(DomainName))
  add(formData_773329, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(formData_773329, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_773328, "Action", newJString(Action))
  add(query_773328, "Version", newJString(Version))
  result = call_773327.call(nil, query_773328, nil, formData_773329, nil)

var postDefineExpression* = Call_PostDefineExpression_773311(
    name: "postDefineExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_PostDefineExpression_773312, base: "/",
    url: url_PostDefineExpression_773313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineExpression_773293 = ref object of OpenApiRestCall_772597
proc url_GetDefineExpression_773295(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineExpression_773294(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Expression.ExpressionValue: JString
  ##                             : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   Expression.ExpressionName: JString
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773296 = query.getOrDefault("Action")
  valid_773296 = validateParameter(valid_773296, JString, required = true,
                                 default = newJString("DefineExpression"))
  if valid_773296 != nil:
    section.add "Action", valid_773296
  var valid_773297 = query.getOrDefault("Expression.ExpressionValue")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "Expression.ExpressionValue", valid_773297
  var valid_773298 = query.getOrDefault("Expression.ExpressionName")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "Expression.ExpressionName", valid_773298
  var valid_773299 = query.getOrDefault("DomainName")
  valid_773299 = validateParameter(valid_773299, JString, required = true,
                                 default = nil)
  if valid_773299 != nil:
    section.add "DomainName", valid_773299
  var valid_773300 = query.getOrDefault("Version")
  valid_773300 = validateParameter(valid_773300, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773300 != nil:
    section.add "Version", valid_773300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773301 = header.getOrDefault("X-Amz-Date")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Date", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Security-Token")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Security-Token", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Content-Sha256", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Algorithm")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Algorithm", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Signature")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Signature", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-SignedHeaders", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Credential")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Credential", valid_773307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773308: Call_GetDefineExpression_773293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773308.validator(path, query, header, formData, body)
  let scheme = call_773308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773308.url(scheme.get, call_773308.host, call_773308.base,
                         call_773308.route, valid.getOrDefault("path"))
  result = hook(call_773308, url, valid)

proc call*(call_773309: Call_GetDefineExpression_773293; DomainName: string;
          Action: string = "DefineExpression";
          ExpressionExpressionValue: string = "";
          ExpressionExpressionName: string = ""; Version: string = "2013-01-01"): Recallable =
  ## getDefineExpression
  ## Configures an <code><a>Expression</a></code> for the search domain. Used to create new expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   ExpressionExpressionValue: string
  ##                            : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   ExpressionExpressionName: string
  ##                           : A named expression that can be evaluated at search time. Can be used to sort the search results, define other expressions, or return computed information in the search results. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773310 = newJObject()
  add(query_773310, "Action", newJString(Action))
  add(query_773310, "Expression.ExpressionValue",
      newJString(ExpressionExpressionValue))
  add(query_773310, "Expression.ExpressionName",
      newJString(ExpressionExpressionName))
  add(query_773310, "DomainName", newJString(DomainName))
  add(query_773310, "Version", newJString(Version))
  result = call_773309.call(nil, query_773310, nil, nil, nil)

var getDefineExpression* = Call_GetDefineExpression_773293(
    name: "getDefineExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineExpression",
    validator: validate_GetDefineExpression_773294, base: "/",
    url: url_GetDefineExpression_773295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_773359 = ref object of OpenApiRestCall_772597
proc url_PostDefineIndexField_773361(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineIndexField_773360(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773362 = query.getOrDefault("Action")
  valid_773362 = validateParameter(valid_773362, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_773362 != nil:
    section.add "Action", valid_773362
  var valid_773363 = query.getOrDefault("Version")
  valid_773363 = validateParameter(valid_773363, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773363 != nil:
    section.add "Version", valid_773363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773364 = header.getOrDefault("X-Amz-Date")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Date", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Security-Token")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Security-Token", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-Content-Sha256", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-Algorithm")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Algorithm", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-Signature")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-Signature", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-SignedHeaders", valid_773369
  var valid_773370 = header.getOrDefault("X-Amz-Credential")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Credential", valid_773370
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.TextOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  section = newJObject()
  var valid_773371 = formData.getOrDefault("IndexField.TextArrayOptions")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "IndexField.TextArrayOptions", valid_773371
  var valid_773372 = formData.getOrDefault("IndexField.DateArrayOptions")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "IndexField.DateArrayOptions", valid_773372
  var valid_773373 = formData.getOrDefault("IndexField.TextOptions")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "IndexField.TextOptions", valid_773373
  var valid_773374 = formData.getOrDefault("IndexField.DoubleOptions")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "IndexField.DoubleOptions", valid_773374
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773375 = formData.getOrDefault("DomainName")
  valid_773375 = validateParameter(valid_773375, JString, required = true,
                                 default = nil)
  if valid_773375 != nil:
    section.add "DomainName", valid_773375
  var valid_773376 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "IndexField.LiteralOptions", valid_773376
  var valid_773377 = formData.getOrDefault("IndexField.LiteralArrayOptions")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_773377
  var valid_773378 = formData.getOrDefault("IndexField.DateOptions")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "IndexField.DateOptions", valid_773378
  var valid_773379 = formData.getOrDefault("IndexField.IntOptions")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "IndexField.IntOptions", valid_773379
  var valid_773380 = formData.getOrDefault("IndexField.LatLonOptions")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "IndexField.LatLonOptions", valid_773380
  var valid_773381 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "IndexField.IndexFieldType", valid_773381
  var valid_773382 = formData.getOrDefault("IndexField.DoubleArrayOptions")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_773382
  var valid_773383 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "IndexField.IndexFieldName", valid_773383
  var valid_773384 = formData.getOrDefault("IndexField.IntArrayOptions")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "IndexField.IntArrayOptions", valid_773384
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773385: Call_PostDefineIndexField_773359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_773385.validator(path, query, header, formData, body)
  let scheme = call_773385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773385.url(scheme.get, call_773385.host, call_773385.base,
                         call_773385.route, valid.getOrDefault("path"))
  result = hook(call_773385, url, valid)

proc call*(call_773386: Call_PostDefineIndexField_773359; DomainName: string;
          IndexFieldTextArrayOptions: string = "";
          IndexFieldDateArrayOptions: string = "";
          IndexFieldTextOptions: string = ""; IndexFieldDoubleOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldDateOptions: string = ""; IndexFieldIntOptions: string = "";
          IndexFieldLatLonOptions: string = "";
          IndexFieldIndexFieldType: string = "";
          Action: string = "DefineIndexField";
          IndexFieldDoubleArrayOptions: string = "";
          IndexFieldIndexFieldName: string = ""; Version: string = "2013-01-01";
          IndexFieldIntArrayOptions: string = ""): Recallable =
  ## postDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   Version: string (required)
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  var query_773387 = newJObject()
  var formData_773388 = newJObject()
  add(formData_773388, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(formData_773388, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(formData_773388, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_773388, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(formData_773388, "DomainName", newJString(DomainName))
  add(formData_773388, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_773388, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(formData_773388, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(formData_773388, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(formData_773388, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(formData_773388, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_773387, "Action", newJString(Action))
  add(formData_773388, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(formData_773388, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_773387, "Version", newJString(Version))
  add(formData_773388, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  result = call_773386.call(nil, query_773387, nil, formData_773388, nil)

var postDefineIndexField* = Call_PostDefineIndexField_773359(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_773360, base: "/",
    url: url_PostDefineIndexField_773361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_773330 = ref object of OpenApiRestCall_772597
proc url_GetDefineIndexField_773332(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineIndexField_773331(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateOptions: JString
  ##                         : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralOptions: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.LiteralArrayOptions: JString
  ##                                 : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldType: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntOptions: JString
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DateArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IndexFieldName: JString
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexField.LatLonOptions: JString
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.IntArrayOptions: JString
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexField.TextArrayOptions: JString
  ##                              : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexField.DoubleArrayOptions: JString
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: JString (required)
  section = newJObject()
  var valid_773333 = query.getOrDefault("IndexField.TextOptions")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "IndexField.TextOptions", valid_773333
  var valid_773334 = query.getOrDefault("IndexField.DateOptions")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "IndexField.DateOptions", valid_773334
  var valid_773335 = query.getOrDefault("IndexField.LiteralOptions")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "IndexField.LiteralOptions", valid_773335
  var valid_773336 = query.getOrDefault("IndexField.LiteralArrayOptions")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "IndexField.LiteralArrayOptions", valid_773336
  var valid_773337 = query.getOrDefault("IndexField.IndexFieldType")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "IndexField.IndexFieldType", valid_773337
  var valid_773338 = query.getOrDefault("IndexField.IntOptions")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "IndexField.IntOptions", valid_773338
  var valid_773339 = query.getOrDefault("IndexField.DateArrayOptions")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "IndexField.DateArrayOptions", valid_773339
  var valid_773340 = query.getOrDefault("IndexField.DoubleOptions")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "IndexField.DoubleOptions", valid_773340
  var valid_773341 = query.getOrDefault("IndexField.IndexFieldName")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "IndexField.IndexFieldName", valid_773341
  var valid_773342 = query.getOrDefault("IndexField.LatLonOptions")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "IndexField.LatLonOptions", valid_773342
  var valid_773343 = query.getOrDefault("IndexField.IntArrayOptions")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "IndexField.IntArrayOptions", valid_773343
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773344 = query.getOrDefault("Action")
  valid_773344 = validateParameter(valid_773344, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_773344 != nil:
    section.add "Action", valid_773344
  var valid_773345 = query.getOrDefault("DomainName")
  valid_773345 = validateParameter(valid_773345, JString, required = true,
                                 default = nil)
  if valid_773345 != nil:
    section.add "DomainName", valid_773345
  var valid_773346 = query.getOrDefault("IndexField.TextArrayOptions")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "IndexField.TextArrayOptions", valid_773346
  var valid_773347 = query.getOrDefault("IndexField.DoubleArrayOptions")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "IndexField.DoubleArrayOptions", valid_773347
  var valid_773348 = query.getOrDefault("Version")
  valid_773348 = validateParameter(valid_773348, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773348 != nil:
    section.add "Version", valid_773348
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773349 = header.getOrDefault("X-Amz-Date")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Date", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Security-Token")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Security-Token", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Content-Sha256", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-Algorithm")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-Algorithm", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Signature")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Signature", valid_773353
  var valid_773354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-SignedHeaders", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Credential")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Credential", valid_773355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773356: Call_GetDefineIndexField_773330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_773356.validator(path, query, header, formData, body)
  let scheme = call_773356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773356.url(scheme.get, call_773356.host, call_773356.base,
                         call_773356.route, valid.getOrDefault("path"))
  result = hook(call_773356, url, valid)

proc call*(call_773357: Call_GetDefineIndexField_773330; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldDateOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          IndexFieldLiteralArrayOptions: string = "";
          IndexFieldIndexFieldType: string = ""; IndexFieldIntOptions: string = "";
          IndexFieldDateArrayOptions: string = "";
          IndexFieldDoubleOptions: string = "";
          IndexFieldIndexFieldName: string = "";
          IndexFieldLatLonOptions: string = "";
          IndexFieldIntArrayOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldTextArrayOptions: string = "";
          IndexFieldDoubleArrayOptions: string = ""; Version: string = "2013-01-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code><a>IndexField</a></code> for the search domain. Used to create new fields and modify existing ones. You must specify the name of the domain you are configuring and an index field configuration. The index field configuration specifies a unique name, the index field type, and the options you want to configure for the field. The options you can specify depend on the <code><a>IndexFieldType</a></code>. If the field exists, the new configuration replaces the old one. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   IndexFieldTextOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateOptions: string
  ##                        : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralOptions: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldLiteralArrayOptions: string
  ##                                : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldType: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntOptions: string
  ##                       : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDateArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIndexFieldName: string
  ##                           : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## <p>A string that represents the name of an index field. CloudSearch supports regular index fields as well as dynamic fields. A dynamic field's name defines a pattern that begins or ends with a wildcard. Any document fields that don't map to a regular index field but do match a dynamic field's pattern are configured with the dynamic field's indexing options. </p> <p>Regular field names begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Dynamic field names must begin or end with a wildcard (*). The wildcard can also be the only character in a dynamic field name. Multiple wildcards, and wildcards embedded within a string are not supported. </p> <p>The name <code>score</code> is reserved and cannot be used as a field name. To reference a document's ID, you can use the name <code>_id</code>. </p>
  ##   IndexFieldLatLonOptions: string
  ##                          : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldIntArrayOptions: string
  ##                            : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldTextArrayOptions: string
  ##                             : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   IndexFieldDoubleArrayOptions: string
  ##                               : Configuration information for a field in the index, including its name, type, and options. The supported options depend on the <code><a>IndexFieldType</a></code>.
  ## 
  ##   Version: string (required)
  var query_773358 = newJObject()
  add(query_773358, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_773358, "IndexField.DateOptions", newJString(IndexFieldDateOptions))
  add(query_773358, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_773358, "IndexField.LiteralArrayOptions",
      newJString(IndexFieldLiteralArrayOptions))
  add(query_773358, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_773358, "IndexField.IntOptions", newJString(IndexFieldIntOptions))
  add(query_773358, "IndexField.DateArrayOptions",
      newJString(IndexFieldDateArrayOptions))
  add(query_773358, "IndexField.DoubleOptions",
      newJString(IndexFieldDoubleOptions))
  add(query_773358, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_773358, "IndexField.LatLonOptions",
      newJString(IndexFieldLatLonOptions))
  add(query_773358, "IndexField.IntArrayOptions",
      newJString(IndexFieldIntArrayOptions))
  add(query_773358, "Action", newJString(Action))
  add(query_773358, "DomainName", newJString(DomainName))
  add(query_773358, "IndexField.TextArrayOptions",
      newJString(IndexFieldTextArrayOptions))
  add(query_773358, "IndexField.DoubleArrayOptions",
      newJString(IndexFieldDoubleArrayOptions))
  add(query_773358, "Version", newJString(Version))
  result = call_773357.call(nil, query_773358, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_773330(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_773331, base: "/",
    url: url_GetDefineIndexField_773332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineSuggester_773407 = ref object of OpenApiRestCall_772597
proc url_PostDefineSuggester_773409(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineSuggester_773408(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773410 = query.getOrDefault("Action")
  valid_773410 = validateParameter(valid_773410, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_773410 != nil:
    section.add "Action", valid_773410
  var valid_773411 = query.getOrDefault("Version")
  valid_773411 = validateParameter(valid_773411, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773411 != nil:
    section.add "Version", valid_773411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773412 = header.getOrDefault("X-Amz-Date")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Date", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Security-Token")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Security-Token", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Content-Sha256", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Algorithm")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Algorithm", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Signature")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Signature", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-SignedHeaders", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Credential")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Credential", valid_773418
  result.add "header", section
  ## parameters in `formData` object:
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  section = newJObject()
  var valid_773419 = formData.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_773419
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773420 = formData.getOrDefault("DomainName")
  valid_773420 = validateParameter(valid_773420, JString, required = true,
                                 default = nil)
  if valid_773420 != nil:
    section.add "DomainName", valid_773420
  var valid_773421 = formData.getOrDefault("Suggester.SuggesterName")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "Suggester.SuggesterName", valid_773421
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773422: Call_PostDefineSuggester_773407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773422.validator(path, query, header, formData, body)
  let scheme = call_773422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773422.url(scheme.get, call_773422.host, call_773422.base,
                         call_773422.route, valid.getOrDefault("path"))
  result = hook(call_773422, url, valid)

proc call*(call_773423: Call_PostDefineSuggester_773407; DomainName: string;
          SuggesterDocumentSuggesterOptions: string = "";
          Action: string = "DefineSuggester"; Version: string = "2013-01-01";
          SuggesterSuggesterName: string = ""): Recallable =
  ## postDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  var query_773424 = newJObject()
  var formData_773425 = newJObject()
  add(formData_773425, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(formData_773425, "DomainName", newJString(DomainName))
  add(query_773424, "Action", newJString(Action))
  add(query_773424, "Version", newJString(Version))
  add(formData_773425, "Suggester.SuggesterName",
      newJString(SuggesterSuggesterName))
  result = call_773423.call(nil, query_773424, nil, formData_773425, nil)

var postDefineSuggester* = Call_PostDefineSuggester_773407(
    name: "postDefineSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_PostDefineSuggester_773408, base: "/",
    url: url_PostDefineSuggester_773409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineSuggester_773389 = ref object of OpenApiRestCall_772597
proc url_GetDefineSuggester_773391(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineSuggester_773390(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Suggester.SuggesterName: JString
  ##                          : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: JString (required)
  ##   Suggester.DocumentSuggesterOptions: JString
  ##                                     : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_773392 = query.getOrDefault("Suggester.SuggesterName")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "Suggester.SuggesterName", valid_773392
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773393 = query.getOrDefault("Action")
  valid_773393 = validateParameter(valid_773393, JString, required = true,
                                 default = newJString("DefineSuggester"))
  if valid_773393 != nil:
    section.add "Action", valid_773393
  var valid_773394 = query.getOrDefault("Suggester.DocumentSuggesterOptions")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "Suggester.DocumentSuggesterOptions", valid_773394
  var valid_773395 = query.getOrDefault("DomainName")
  valid_773395 = validateParameter(valid_773395, JString, required = true,
                                 default = nil)
  if valid_773395 != nil:
    section.add "DomainName", valid_773395
  var valid_773396 = query.getOrDefault("Version")
  valid_773396 = validateParameter(valid_773396, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773396 != nil:
    section.add "Version", valid_773396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773397 = header.getOrDefault("X-Amz-Date")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Date", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Security-Token")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Security-Token", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Content-Sha256", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-Algorithm")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Algorithm", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Signature")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Signature", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-SignedHeaders", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Credential")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Credential", valid_773403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773404: Call_GetDefineSuggester_773389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773404.validator(path, query, header, formData, body)
  let scheme = call_773404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773404.url(scheme.get, call_773404.host, call_773404.base,
                         call_773404.route, valid.getOrDefault("path"))
  result = hook(call_773404, url, valid)

proc call*(call_773405: Call_GetDefineSuggester_773389; DomainName: string;
          SuggesterSuggesterName: string = ""; Action: string = "DefineSuggester";
          SuggesterDocumentSuggesterOptions: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## getDefineSuggester
  ## Configures a suggester for a domain. A suggester enables you to display possible matches before users finish typing their queries. When you configure a suggester, you must specify the name of the text field you want to search for possible matches and a unique name for the suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   SuggesterSuggesterName: string
  ##                         : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   Action: string (required)
  ##   SuggesterDocumentSuggesterOptions: string
  ##                                    : Configuration information for a search suggester. Each suggester has a unique name and specifies the text field you want to use for suggestions. The following options can be configured for a suggester: <code>FuzzyMatching</code>, <code>SortExpression</code>. 
  ## 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773406 = newJObject()
  add(query_773406, "Suggester.SuggesterName", newJString(SuggesterSuggesterName))
  add(query_773406, "Action", newJString(Action))
  add(query_773406, "Suggester.DocumentSuggesterOptions",
      newJString(SuggesterDocumentSuggesterOptions))
  add(query_773406, "DomainName", newJString(DomainName))
  add(query_773406, "Version", newJString(Version))
  result = call_773405.call(nil, query_773406, nil, nil, nil)

var getDefineSuggester* = Call_GetDefineSuggester_773389(
    name: "getDefineSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineSuggester",
    validator: validate_GetDefineSuggester_773390, base: "/",
    url: url_GetDefineSuggester_773391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteAnalysisScheme_773443 = ref object of OpenApiRestCall_772597
proc url_PostDeleteAnalysisScheme_773445(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteAnalysisScheme_773444(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773446 = query.getOrDefault("Action")
  valid_773446 = validateParameter(valid_773446, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_773446 != nil:
    section.add "Action", valid_773446
  var valid_773447 = query.getOrDefault("Version")
  valid_773447 = validateParameter(valid_773447, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773447 != nil:
    section.add "Version", valid_773447
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773448 = header.getOrDefault("X-Amz-Date")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Date", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Security-Token")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Security-Token", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Content-Sha256", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-Algorithm")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Algorithm", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Signature")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Signature", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-SignedHeaders", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Credential")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Credential", valid_773454
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773455 = formData.getOrDefault("DomainName")
  valid_773455 = validateParameter(valid_773455, JString, required = true,
                                 default = nil)
  if valid_773455 != nil:
    section.add "DomainName", valid_773455
  var valid_773456 = formData.getOrDefault("AnalysisSchemeName")
  valid_773456 = validateParameter(valid_773456, JString, required = true,
                                 default = nil)
  if valid_773456 != nil:
    section.add "AnalysisSchemeName", valid_773456
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773457: Call_PostDeleteAnalysisScheme_773443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_773457.validator(path, query, header, formData, body)
  let scheme = call_773457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773457.url(scheme.get, call_773457.host, call_773457.base,
                         call_773457.route, valid.getOrDefault("path"))
  result = hook(call_773457, url, valid)

proc call*(call_773458: Call_PostDeleteAnalysisScheme_773443; DomainName: string;
          AnalysisSchemeName: string; Action: string = "DeleteAnalysisScheme";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773459 = newJObject()
  var formData_773460 = newJObject()
  add(formData_773460, "DomainName", newJString(DomainName))
  add(formData_773460, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_773459, "Action", newJString(Action))
  add(query_773459, "Version", newJString(Version))
  result = call_773458.call(nil, query_773459, nil, formData_773460, nil)

var postDeleteAnalysisScheme* = Call_PostDeleteAnalysisScheme_773443(
    name: "postDeleteAnalysisScheme", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_PostDeleteAnalysisScheme_773444, base: "/",
    url: url_PostDeleteAnalysisScheme_773445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteAnalysisScheme_773426 = ref object of OpenApiRestCall_772597
proc url_GetDeleteAnalysisScheme_773428(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteAnalysisScheme_773427(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: JString (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773429 = query.getOrDefault("Action")
  valid_773429 = validateParameter(valid_773429, JString, required = true,
                                 default = newJString("DeleteAnalysisScheme"))
  if valid_773429 != nil:
    section.add "Action", valid_773429
  var valid_773430 = query.getOrDefault("DomainName")
  valid_773430 = validateParameter(valid_773430, JString, required = true,
                                 default = nil)
  if valid_773430 != nil:
    section.add "DomainName", valid_773430
  var valid_773431 = query.getOrDefault("AnalysisSchemeName")
  valid_773431 = validateParameter(valid_773431, JString, required = true,
                                 default = nil)
  if valid_773431 != nil:
    section.add "AnalysisSchemeName", valid_773431
  var valid_773432 = query.getOrDefault("Version")
  valid_773432 = validateParameter(valid_773432, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773432 != nil:
    section.add "Version", valid_773432
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773433 = header.getOrDefault("X-Amz-Date")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Date", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Security-Token")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Security-Token", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Content-Sha256", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Algorithm")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Algorithm", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-Signature")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Signature", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-SignedHeaders", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Credential")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Credential", valid_773439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773440: Call_GetDeleteAnalysisScheme_773426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_773440.validator(path, query, header, formData, body)
  let scheme = call_773440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773440.url(scheme.get, call_773440.host, call_773440.base,
                         call_773440.route, valid.getOrDefault("path"))
  result = hook(call_773440, url, valid)

proc call*(call_773441: Call_GetDeleteAnalysisScheme_773426; DomainName: string;
          AnalysisSchemeName: string; Action: string = "DeleteAnalysisScheme";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteAnalysisScheme
  ## Deletes an analysis scheme. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AnalysisSchemeName: string (required)
  ##                     : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: string (required)
  var query_773442 = newJObject()
  add(query_773442, "Action", newJString(Action))
  add(query_773442, "DomainName", newJString(DomainName))
  add(query_773442, "AnalysisSchemeName", newJString(AnalysisSchemeName))
  add(query_773442, "Version", newJString(Version))
  result = call_773441.call(nil, query_773442, nil, nil, nil)

var getDeleteAnalysisScheme* = Call_GetDeleteAnalysisScheme_773426(
    name: "getDeleteAnalysisScheme", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteAnalysisScheme",
    validator: validate_GetDeleteAnalysisScheme_773427, base: "/",
    url: url_GetDeleteAnalysisScheme_773428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_773477 = ref object of OpenApiRestCall_772597
proc url_PostDeleteDomain_773479(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDomain_773478(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773480 = query.getOrDefault("Action")
  valid_773480 = validateParameter(valid_773480, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_773480 != nil:
    section.add "Action", valid_773480
  var valid_773481 = query.getOrDefault("Version")
  valid_773481 = validateParameter(valid_773481, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773481 != nil:
    section.add "Version", valid_773481
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773482 = header.getOrDefault("X-Amz-Date")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Date", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Security-Token")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Security-Token", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Content-Sha256", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Algorithm")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Algorithm", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Signature")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Signature", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-SignedHeaders", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Credential")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Credential", valid_773488
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773489 = formData.getOrDefault("DomainName")
  valid_773489 = validateParameter(valid_773489, JString, required = true,
                                 default = nil)
  if valid_773489 != nil:
    section.add "DomainName", valid_773489
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773490: Call_PostDeleteDomain_773477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_773490.validator(path, query, header, formData, body)
  let scheme = call_773490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773490.url(scheme.get, call_773490.host, call_773490.base,
                         call_773490.route, valid.getOrDefault("path"))
  result = hook(call_773490, url, valid)

proc call*(call_773491: Call_PostDeleteDomain_773477; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773492 = newJObject()
  var formData_773493 = newJObject()
  add(formData_773493, "DomainName", newJString(DomainName))
  add(query_773492, "Action", newJString(Action))
  add(query_773492, "Version", newJString(Version))
  result = call_773491.call(nil, query_773492, nil, formData_773493, nil)

var postDeleteDomain* = Call_PostDeleteDomain_773477(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_773478,
    base: "/", url: url_PostDeleteDomain_773479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_773461 = ref object of OpenApiRestCall_772597
proc url_GetDeleteDomain_773463(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDomain_773462(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773464 = query.getOrDefault("Action")
  valid_773464 = validateParameter(valid_773464, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_773464 != nil:
    section.add "Action", valid_773464
  var valid_773465 = query.getOrDefault("DomainName")
  valid_773465 = validateParameter(valid_773465, JString, required = true,
                                 default = nil)
  if valid_773465 != nil:
    section.add "DomainName", valid_773465
  var valid_773466 = query.getOrDefault("Version")
  valid_773466 = validateParameter(valid_773466, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773466 != nil:
    section.add "Version", valid_773466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773467 = header.getOrDefault("X-Amz-Date")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Date", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Security-Token")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Security-Token", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Content-Sha256", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Algorithm")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Algorithm", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Signature")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Signature", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-SignedHeaders", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Credential")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Credential", valid_773473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773474: Call_GetDeleteDomain_773461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_773474.validator(path, query, header, formData, body)
  let scheme = call_773474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773474.url(scheme.get, call_773474.host, call_773474.base,
                         call_773474.route, valid.getOrDefault("path"))
  result = hook(call_773474, url, valid)

proc call*(call_773475: Call_GetDeleteDomain_773461; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2013-01-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data. Once a domain has been deleted, it cannot be recovered. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/deleting-domains.html" target="_blank">Deleting a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773476 = newJObject()
  add(query_773476, "Action", newJString(Action))
  add(query_773476, "DomainName", newJString(DomainName))
  add(query_773476, "Version", newJString(Version))
  result = call_773475.call(nil, query_773476, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_773461(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_773462,
    base: "/", url: url_GetDeleteDomain_773463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteExpression_773511 = ref object of OpenApiRestCall_772597
proc url_PostDeleteExpression_773513(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteExpression_773512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773514 = query.getOrDefault("Action")
  valid_773514 = validateParameter(valid_773514, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_773514 != nil:
    section.add "Action", valid_773514
  var valid_773515 = query.getOrDefault("Version")
  valid_773515 = validateParameter(valid_773515, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773515 != nil:
    section.add "Version", valid_773515
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773516 = header.getOrDefault("X-Amz-Date")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Date", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Security-Token")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Security-Token", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Content-Sha256", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Algorithm")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Algorithm", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Signature")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Signature", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-SignedHeaders", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Credential")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Credential", valid_773522
  result.add "header", section
  ## parameters in `formData` object:
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ExpressionName` field"
  var valid_773523 = formData.getOrDefault("ExpressionName")
  valid_773523 = validateParameter(valid_773523, JString, required = true,
                                 default = nil)
  if valid_773523 != nil:
    section.add "ExpressionName", valid_773523
  var valid_773524 = formData.getOrDefault("DomainName")
  valid_773524 = validateParameter(valid_773524, JString, required = true,
                                 default = nil)
  if valid_773524 != nil:
    section.add "DomainName", valid_773524
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773525: Call_PostDeleteExpression_773511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773525.validator(path, query, header, formData, body)
  let scheme = call_773525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773525.url(scheme.get, call_773525.host, call_773525.base,
                         call_773525.route, valid.getOrDefault("path"))
  result = hook(call_773525, url, valid)

proc call*(call_773526: Call_PostDeleteExpression_773511; ExpressionName: string;
          DomainName: string; Action: string = "DeleteExpression";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773527 = newJObject()
  var formData_773528 = newJObject()
  add(formData_773528, "ExpressionName", newJString(ExpressionName))
  add(formData_773528, "DomainName", newJString(DomainName))
  add(query_773527, "Action", newJString(Action))
  add(query_773527, "Version", newJString(Version))
  result = call_773526.call(nil, query_773527, nil, formData_773528, nil)

var postDeleteExpression* = Call_PostDeleteExpression_773511(
    name: "postDeleteExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_PostDeleteExpression_773512, base: "/",
    url: url_PostDeleteExpression_773513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteExpression_773494 = ref object of OpenApiRestCall_772597
proc url_GetDeleteExpression_773496(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteExpression_773495(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ExpressionName: JString (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773497 = query.getOrDefault("Action")
  valid_773497 = validateParameter(valid_773497, JString, required = true,
                                 default = newJString("DeleteExpression"))
  if valid_773497 != nil:
    section.add "Action", valid_773497
  var valid_773498 = query.getOrDefault("ExpressionName")
  valid_773498 = validateParameter(valid_773498, JString, required = true,
                                 default = nil)
  if valid_773498 != nil:
    section.add "ExpressionName", valid_773498
  var valid_773499 = query.getOrDefault("DomainName")
  valid_773499 = validateParameter(valid_773499, JString, required = true,
                                 default = nil)
  if valid_773499 != nil:
    section.add "DomainName", valid_773499
  var valid_773500 = query.getOrDefault("Version")
  valid_773500 = validateParameter(valid_773500, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773500 != nil:
    section.add "Version", valid_773500
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773501 = header.getOrDefault("X-Amz-Date")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Date", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Security-Token")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Security-Token", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Content-Sha256", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Algorithm")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Algorithm", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Signature")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Signature", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-SignedHeaders", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Credential")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Credential", valid_773507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773508: Call_GetDeleteExpression_773494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773508.validator(path, query, header, formData, body)
  let scheme = call_773508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773508.url(scheme.get, call_773508.host, call_773508.base,
                         call_773508.route, valid.getOrDefault("path"))
  result = hook(call_773508, url, valid)

proc call*(call_773509: Call_GetDeleteExpression_773494; ExpressionName: string;
          DomainName: string; Action: string = "DeleteExpression";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteExpression
  ## Removes an <code><a>Expression</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   ExpressionName: string (required)
  ##                 : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773510 = newJObject()
  add(query_773510, "Action", newJString(Action))
  add(query_773510, "ExpressionName", newJString(ExpressionName))
  add(query_773510, "DomainName", newJString(DomainName))
  add(query_773510, "Version", newJString(Version))
  result = call_773509.call(nil, query_773510, nil, nil, nil)

var getDeleteExpression* = Call_GetDeleteExpression_773494(
    name: "getDeleteExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteExpression",
    validator: validate_GetDeleteExpression_773495, base: "/",
    url: url_GetDeleteExpression_773496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_773546 = ref object of OpenApiRestCall_772597
proc url_PostDeleteIndexField_773548(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteIndexField_773547(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773549 = query.getOrDefault("Action")
  valid_773549 = validateParameter(valid_773549, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_773549 != nil:
    section.add "Action", valid_773549
  var valid_773550 = query.getOrDefault("Version")
  valid_773550 = validateParameter(valid_773550, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773550 != nil:
    section.add "Version", valid_773550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773551 = header.getOrDefault("X-Amz-Date")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Date", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Security-Token")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Security-Token", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Content-Sha256", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Algorithm")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Algorithm", valid_773554
  var valid_773555 = header.getOrDefault("X-Amz-Signature")
  valid_773555 = validateParameter(valid_773555, JString, required = false,
                                 default = nil)
  if valid_773555 != nil:
    section.add "X-Amz-Signature", valid_773555
  var valid_773556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773556 = validateParameter(valid_773556, JString, required = false,
                                 default = nil)
  if valid_773556 != nil:
    section.add "X-Amz-SignedHeaders", valid_773556
  var valid_773557 = header.getOrDefault("X-Amz-Credential")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Credential", valid_773557
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773558 = formData.getOrDefault("DomainName")
  valid_773558 = validateParameter(valid_773558, JString, required = true,
                                 default = nil)
  if valid_773558 != nil:
    section.add "DomainName", valid_773558
  var valid_773559 = formData.getOrDefault("IndexFieldName")
  valid_773559 = validateParameter(valid_773559, JString, required = true,
                                 default = nil)
  if valid_773559 != nil:
    section.add "IndexFieldName", valid_773559
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773560: Call_PostDeleteIndexField_773546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773560.validator(path, query, header, formData, body)
  let scheme = call_773560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773560.url(scheme.get, call_773560.host, call_773560.base,
                         call_773560.route, valid.getOrDefault("path"))
  result = hook(call_773560, url, valid)

proc call*(call_773561: Call_PostDeleteIndexField_773546; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   IndexFieldName: string (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773562 = newJObject()
  var formData_773563 = newJObject()
  add(formData_773563, "DomainName", newJString(DomainName))
  add(formData_773563, "IndexFieldName", newJString(IndexFieldName))
  add(query_773562, "Action", newJString(Action))
  add(query_773562, "Version", newJString(Version))
  result = call_773561.call(nil, query_773562, nil, formData_773563, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_773546(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_773547, base: "/",
    url: url_PostDeleteIndexField_773548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_773529 = ref object of OpenApiRestCall_772597
proc url_GetDeleteIndexField_773531(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteIndexField_773530(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexFieldName: JString (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `IndexFieldName` field"
  var valid_773532 = query.getOrDefault("IndexFieldName")
  valid_773532 = validateParameter(valid_773532, JString, required = true,
                                 default = nil)
  if valid_773532 != nil:
    section.add "IndexFieldName", valid_773532
  var valid_773533 = query.getOrDefault("Action")
  valid_773533 = validateParameter(valid_773533, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_773533 != nil:
    section.add "Action", valid_773533
  var valid_773534 = query.getOrDefault("DomainName")
  valid_773534 = validateParameter(valid_773534, JString, required = true,
                                 default = nil)
  if valid_773534 != nil:
    section.add "DomainName", valid_773534
  var valid_773535 = query.getOrDefault("Version")
  valid_773535 = validateParameter(valid_773535, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773535 != nil:
    section.add "Version", valid_773535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773536 = header.getOrDefault("X-Amz-Date")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Date", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Security-Token")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Security-Token", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Content-Sha256", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Algorithm")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Algorithm", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Signature")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Signature", valid_773540
  var valid_773541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "X-Amz-SignedHeaders", valid_773541
  var valid_773542 = header.getOrDefault("X-Amz-Credential")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Credential", valid_773542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773543: Call_GetDeleteIndexField_773529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773543.validator(path, query, header, formData, body)
  let scheme = call_773543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773543.url(scheme.get, call_773543.host, call_773543.base,
                         call_773543.route, valid.getOrDefault("path"))
  result = hook(call_773543, url, valid)

proc call*(call_773544: Call_GetDeleteIndexField_773529; IndexFieldName: string;
          DomainName: string; Action: string = "DeleteIndexField";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code><a>IndexField</a></code> from the search domain. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-index-fields.html" target="_blank">Configuring Index Fields</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   IndexFieldName: string (required)
  ##                 : The name of the index field your want to remove from the domain's indexing options.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773545 = newJObject()
  add(query_773545, "IndexFieldName", newJString(IndexFieldName))
  add(query_773545, "Action", newJString(Action))
  add(query_773545, "DomainName", newJString(DomainName))
  add(query_773545, "Version", newJString(Version))
  result = call_773544.call(nil, query_773545, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_773529(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_773530, base: "/",
    url: url_GetDeleteIndexField_773531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteSuggester_773581 = ref object of OpenApiRestCall_772597
proc url_PostDeleteSuggester_773583(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteSuggester_773582(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773584 = query.getOrDefault("Action")
  valid_773584 = validateParameter(valid_773584, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_773584 != nil:
    section.add "Action", valid_773584
  var valid_773585 = query.getOrDefault("Version")
  valid_773585 = validateParameter(valid_773585, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773585 != nil:
    section.add "Version", valid_773585
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773586 = header.getOrDefault("X-Amz-Date")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Date", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Security-Token")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Security-Token", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Content-Sha256", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-Algorithm")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-Algorithm", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-Signature")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-Signature", valid_773590
  var valid_773591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-SignedHeaders", valid_773591
  var valid_773592 = header.getOrDefault("X-Amz-Credential")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-Credential", valid_773592
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773593 = formData.getOrDefault("DomainName")
  valid_773593 = validateParameter(valid_773593, JString, required = true,
                                 default = nil)
  if valid_773593 != nil:
    section.add "DomainName", valid_773593
  var valid_773594 = formData.getOrDefault("SuggesterName")
  valid_773594 = validateParameter(valid_773594, JString, required = true,
                                 default = nil)
  if valid_773594 != nil:
    section.add "SuggesterName", valid_773594
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773595: Call_PostDeleteSuggester_773581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773595.validator(path, query, header, formData, body)
  let scheme = call_773595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773595.url(scheme.get, call_773595.host, call_773595.base,
                         call_773595.route, valid.getOrDefault("path"))
  result = hook(call_773595, url, valid)

proc call*(call_773596: Call_PostDeleteSuggester_773581; DomainName: string;
          SuggesterName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## postDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   Version: string (required)
  var query_773597 = newJObject()
  var formData_773598 = newJObject()
  add(formData_773598, "DomainName", newJString(DomainName))
  add(query_773597, "Action", newJString(Action))
  add(formData_773598, "SuggesterName", newJString(SuggesterName))
  add(query_773597, "Version", newJString(Version))
  result = call_773596.call(nil, query_773597, nil, formData_773598, nil)

var postDeleteSuggester* = Call_PostDeleteSuggester_773581(
    name: "postDeleteSuggester", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_PostDeleteSuggester_773582, base: "/",
    url: url_PostDeleteSuggester_773583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteSuggester_773564 = ref object of OpenApiRestCall_772597
proc url_GetDeleteSuggester_773566(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteSuggester_773565(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SuggesterName: JString (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773567 = query.getOrDefault("Action")
  valid_773567 = validateParameter(valid_773567, JString, required = true,
                                 default = newJString("DeleteSuggester"))
  if valid_773567 != nil:
    section.add "Action", valid_773567
  var valid_773568 = query.getOrDefault("SuggesterName")
  valid_773568 = validateParameter(valid_773568, JString, required = true,
                                 default = nil)
  if valid_773568 != nil:
    section.add "SuggesterName", valid_773568
  var valid_773569 = query.getOrDefault("DomainName")
  valid_773569 = validateParameter(valid_773569, JString, required = true,
                                 default = nil)
  if valid_773569 != nil:
    section.add "DomainName", valid_773569
  var valid_773570 = query.getOrDefault("Version")
  valid_773570 = validateParameter(valid_773570, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773570 != nil:
    section.add "Version", valid_773570
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773571 = header.getOrDefault("X-Amz-Date")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-Date", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Security-Token")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Security-Token", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Content-Sha256", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-Algorithm")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-Algorithm", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-Signature")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Signature", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-SignedHeaders", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Credential")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Credential", valid_773577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773578: Call_GetDeleteSuggester_773564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773578.validator(path, query, header, formData, body)
  let scheme = call_773578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773578.url(scheme.get, call_773578.host, call_773578.base,
                         call_773578.route, valid.getOrDefault("path"))
  result = hook(call_773578, url, valid)

proc call*(call_773579: Call_GetDeleteSuggester_773564; SuggesterName: string;
          DomainName: string; Action: string = "DeleteSuggester";
          Version: string = "2013-01-01"): Recallable =
  ## getDeleteSuggester
  ## Deletes a suggester. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   SuggesterName: string (required)
  ##                : Names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore).
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773580 = newJObject()
  add(query_773580, "Action", newJString(Action))
  add(query_773580, "SuggesterName", newJString(SuggesterName))
  add(query_773580, "DomainName", newJString(DomainName))
  add(query_773580, "Version", newJString(Version))
  result = call_773579.call(nil, query_773580, nil, nil, nil)

var getDeleteSuggester* = Call_GetDeleteSuggester_773564(
    name: "getDeleteSuggester", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteSuggester",
    validator: validate_GetDeleteSuggester_773565, base: "/",
    url: url_GetDeleteSuggester_773566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAnalysisSchemes_773617 = ref object of OpenApiRestCall_772597
proc url_PostDescribeAnalysisSchemes_773619(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAnalysisSchemes_773618(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773620 = query.getOrDefault("Action")
  valid_773620 = validateParameter(valid_773620, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_773620 != nil:
    section.add "Action", valid_773620
  var valid_773621 = query.getOrDefault("Version")
  valid_773621 = validateParameter(valid_773621, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773621 != nil:
    section.add "Version", valid_773621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773622 = header.getOrDefault("X-Amz-Date")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Date", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-Security-Token")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-Security-Token", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Content-Sha256", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Algorithm")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Algorithm", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Signature")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Signature", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-SignedHeaders", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Credential")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Credential", valid_773628
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773629 = formData.getOrDefault("DomainName")
  valid_773629 = validateParameter(valid_773629, JString, required = true,
                                 default = nil)
  if valid_773629 != nil:
    section.add "DomainName", valid_773629
  var valid_773630 = formData.getOrDefault("Deployed")
  valid_773630 = validateParameter(valid_773630, JBool, required = false, default = nil)
  if valid_773630 != nil:
    section.add "Deployed", valid_773630
  var valid_773631 = formData.getOrDefault("AnalysisSchemeNames")
  valid_773631 = validateParameter(valid_773631, JArray, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "AnalysisSchemeNames", valid_773631
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773632: Call_PostDescribeAnalysisSchemes_773617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773632.validator(path, query, header, formData, body)
  let scheme = call_773632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773632.url(scheme.get, call_773632.host, call_773632.base,
                         call_773632.route, valid.getOrDefault("path"))
  result = hook(call_773632, url, valid)

proc call*(call_773633: Call_PostDescribeAnalysisSchemes_773617;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAnalysisSchemes";
          AnalysisSchemeNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Version: string (required)
  var query_773634 = newJObject()
  var formData_773635 = newJObject()
  add(formData_773635, "DomainName", newJString(DomainName))
  add(formData_773635, "Deployed", newJBool(Deployed))
  add(query_773634, "Action", newJString(Action))
  if AnalysisSchemeNames != nil:
    formData_773635.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_773634, "Version", newJString(Version))
  result = call_773633.call(nil, query_773634, nil, formData_773635, nil)

var postDescribeAnalysisSchemes* = Call_PostDescribeAnalysisSchemes_773617(
    name: "postDescribeAnalysisSchemes", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_PostDescribeAnalysisSchemes_773618, base: "/",
    url: url_PostDescribeAnalysisSchemes_773619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAnalysisSchemes_773599 = ref object of OpenApiRestCall_772597
proc url_GetDescribeAnalysisSchemes_773601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAnalysisSchemes_773600(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_773602 = query.getOrDefault("Deployed")
  valid_773602 = validateParameter(valid_773602, JBool, required = false, default = nil)
  if valid_773602 != nil:
    section.add "Deployed", valid_773602
  var valid_773603 = query.getOrDefault("AnalysisSchemeNames")
  valid_773603 = validateParameter(valid_773603, JArray, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "AnalysisSchemeNames", valid_773603
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773604 = query.getOrDefault("Action")
  valid_773604 = validateParameter(valid_773604, JString, required = true, default = newJString(
      "DescribeAnalysisSchemes"))
  if valid_773604 != nil:
    section.add "Action", valid_773604
  var valid_773605 = query.getOrDefault("DomainName")
  valid_773605 = validateParameter(valid_773605, JString, required = true,
                                 default = nil)
  if valid_773605 != nil:
    section.add "DomainName", valid_773605
  var valid_773606 = query.getOrDefault("Version")
  valid_773606 = validateParameter(valid_773606, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773606 != nil:
    section.add "Version", valid_773606
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773607 = header.getOrDefault("X-Amz-Date")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-Date", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-Security-Token")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-Security-Token", valid_773608
  var valid_773609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-Content-Sha256", valid_773609
  var valid_773610 = header.getOrDefault("X-Amz-Algorithm")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Algorithm", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Signature")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Signature", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-SignedHeaders", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Credential")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Credential", valid_773613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773614: Call_GetDescribeAnalysisSchemes_773599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773614.validator(path, query, header, formData, body)
  let scheme = call_773614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773614.url(scheme.get, call_773614.host, call_773614.base,
                         call_773614.route, valid.getOrDefault("path"))
  result = hook(call_773614, url, valid)

proc call*(call_773615: Call_GetDescribeAnalysisSchemes_773599; DomainName: string;
          Deployed: bool = false; AnalysisSchemeNames: JsonNode = nil;
          Action: string = "DescribeAnalysisSchemes"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeAnalysisSchemes
  ## Gets the analysis schemes configured for a domain. An analysis scheme defines language-specific text processing options for a <code>text</code> field. Can be limited to specific analysis schemes by name. By default, shows all analysis schemes and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-analysis-schemes.html" target="_blank">Configuring Analysis Schemes</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   AnalysisSchemeNames: JArray
  ##                      : The analysis schemes you want to describe.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773616 = newJObject()
  add(query_773616, "Deployed", newJBool(Deployed))
  if AnalysisSchemeNames != nil:
    query_773616.add "AnalysisSchemeNames", AnalysisSchemeNames
  add(query_773616, "Action", newJString(Action))
  add(query_773616, "DomainName", newJString(DomainName))
  add(query_773616, "Version", newJString(Version))
  result = call_773615.call(nil, query_773616, nil, nil, nil)

var getDescribeAnalysisSchemes* = Call_GetDescribeAnalysisSchemes_773599(
    name: "getDescribeAnalysisSchemes", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeAnalysisSchemes",
    validator: validate_GetDescribeAnalysisSchemes_773600, base: "/",
    url: url_GetDescribeAnalysisSchemes_773601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_773653 = ref object of OpenApiRestCall_772597
proc url_PostDescribeAvailabilityOptions_773655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAvailabilityOptions_773654(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773656 = query.getOrDefault("Action")
  valid_773656 = validateParameter(valid_773656, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_773656 != nil:
    section.add "Action", valid_773656
  var valid_773657 = query.getOrDefault("Version")
  valid_773657 = validateParameter(valid_773657, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773657 != nil:
    section.add "Version", valid_773657
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773658 = header.getOrDefault("X-Amz-Date")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Date", valid_773658
  var valid_773659 = header.getOrDefault("X-Amz-Security-Token")
  valid_773659 = validateParameter(valid_773659, JString, required = false,
                                 default = nil)
  if valid_773659 != nil:
    section.add "X-Amz-Security-Token", valid_773659
  var valid_773660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773660 = validateParameter(valid_773660, JString, required = false,
                                 default = nil)
  if valid_773660 != nil:
    section.add "X-Amz-Content-Sha256", valid_773660
  var valid_773661 = header.getOrDefault("X-Amz-Algorithm")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Algorithm", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Signature")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Signature", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-SignedHeaders", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Credential")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Credential", valid_773664
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773665 = formData.getOrDefault("DomainName")
  valid_773665 = validateParameter(valid_773665, JString, required = true,
                                 default = nil)
  if valid_773665 != nil:
    section.add "DomainName", valid_773665
  var valid_773666 = formData.getOrDefault("Deployed")
  valid_773666 = validateParameter(valid_773666, JBool, required = false, default = nil)
  if valid_773666 != nil:
    section.add "Deployed", valid_773666
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773667: Call_PostDescribeAvailabilityOptions_773653;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773667.validator(path, query, header, formData, body)
  let scheme = call_773667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773667.url(scheme.get, call_773667.host, call_773667.base,
                         call_773667.route, valid.getOrDefault("path"))
  result = hook(call_773667, url, valid)

proc call*(call_773668: Call_PostDescribeAvailabilityOptions_773653;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773669 = newJObject()
  var formData_773670 = newJObject()
  add(formData_773670, "DomainName", newJString(DomainName))
  add(formData_773670, "Deployed", newJBool(Deployed))
  add(query_773669, "Action", newJString(Action))
  add(query_773669, "Version", newJString(Version))
  result = call_773668.call(nil, query_773669, nil, formData_773670, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_773653(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_773654, base: "/",
    url: url_PostDescribeAvailabilityOptions_773655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_773636 = ref object of OpenApiRestCall_772597
proc url_GetDescribeAvailabilityOptions_773638(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAvailabilityOptions_773637(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_773639 = query.getOrDefault("Deployed")
  valid_773639 = validateParameter(valid_773639, JBool, required = false, default = nil)
  if valid_773639 != nil:
    section.add "Deployed", valid_773639
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773640 = query.getOrDefault("Action")
  valid_773640 = validateParameter(valid_773640, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_773640 != nil:
    section.add "Action", valid_773640
  var valid_773641 = query.getOrDefault("DomainName")
  valid_773641 = validateParameter(valid_773641, JString, required = true,
                                 default = nil)
  if valid_773641 != nil:
    section.add "DomainName", valid_773641
  var valid_773642 = query.getOrDefault("Version")
  valid_773642 = validateParameter(valid_773642, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773642 != nil:
    section.add "Version", valid_773642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773643 = header.getOrDefault("X-Amz-Date")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Date", valid_773643
  var valid_773644 = header.getOrDefault("X-Amz-Security-Token")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Security-Token", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Content-Sha256", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-Algorithm")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Algorithm", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Signature")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Signature", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-SignedHeaders", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Credential")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Credential", valid_773649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773650: Call_GetDescribeAvailabilityOptions_773636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773650.validator(path, query, header, formData, body)
  let scheme = call_773650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773650.url(scheme.get, call_773650.host, call_773650.base,
                         call_773650.route, valid.getOrDefault("path"))
  result = hook(call_773650, url, valid)

proc call*(call_773651: Call_GetDescribeAvailabilityOptions_773636;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773652 = newJObject()
  add(query_773652, "Deployed", newJBool(Deployed))
  add(query_773652, "Action", newJString(Action))
  add(query_773652, "DomainName", newJString(DomainName))
  add(query_773652, "Version", newJString(Version))
  result = call_773651.call(nil, query_773652, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_773636(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_773637, base: "/",
    url: url_GetDescribeAvailabilityOptions_773638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_773687 = ref object of OpenApiRestCall_772597
proc url_PostDescribeDomains_773689(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDomains_773688(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773690 = query.getOrDefault("Action")
  valid_773690 = validateParameter(valid_773690, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_773690 != nil:
    section.add "Action", valid_773690
  var valid_773691 = query.getOrDefault("Version")
  valid_773691 = validateParameter(valid_773691, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773691 != nil:
    section.add "Version", valid_773691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773692 = header.getOrDefault("X-Amz-Date")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Date", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Security-Token")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Security-Token", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Content-Sha256", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Algorithm")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Algorithm", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Signature")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Signature", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-SignedHeaders", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-Credential")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-Credential", valid_773698
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_773699 = formData.getOrDefault("DomainNames")
  valid_773699 = validateParameter(valid_773699, JArray, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "DomainNames", valid_773699
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773700: Call_PostDescribeDomains_773687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773700.validator(path, query, header, formData, body)
  let scheme = call_773700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773700.url(scheme.get, call_773700.host, call_773700.base,
                         call_773700.route, valid.getOrDefault("path"))
  result = hook(call_773700, url, valid)

proc call*(call_773701: Call_PostDescribeDomains_773687;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773702 = newJObject()
  var formData_773703 = newJObject()
  if DomainNames != nil:
    formData_773703.add "DomainNames", DomainNames
  add(query_773702, "Action", newJString(Action))
  add(query_773702, "Version", newJString(Version))
  result = call_773701.call(nil, query_773702, nil, formData_773703, nil)

var postDescribeDomains* = Call_PostDescribeDomains_773687(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_773688, base: "/",
    url: url_PostDescribeDomains_773689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_773671 = ref object of OpenApiRestCall_772597
proc url_GetDescribeDomains_773673(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDomains_773672(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_773674 = query.getOrDefault("DomainNames")
  valid_773674 = validateParameter(valid_773674, JArray, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "DomainNames", valid_773674
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773675 = query.getOrDefault("Action")
  valid_773675 = validateParameter(valid_773675, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_773675 != nil:
    section.add "Action", valid_773675
  var valid_773676 = query.getOrDefault("Version")
  valid_773676 = validateParameter(valid_773676, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773676 != nil:
    section.add "Version", valid_773676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773677 = header.getOrDefault("X-Amz-Date")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Date", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Security-Token")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Security-Token", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Content-Sha256", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Algorithm")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Algorithm", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Signature")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Signature", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-SignedHeaders", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Credential")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Credential", valid_773683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773684: Call_GetDescribeDomains_773671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773684.validator(path, query, header, formData, body)
  let scheme = call_773684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773684.url(scheme.get, call_773684.host, call_773684.base,
                         call_773684.route, valid.getOrDefault("path"))
  result = hook(call_773684, url, valid)

proc call*(call_773685: Call_GetDescribeDomains_773671;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default. To get the number of searchable documents in a domain, use the console or submit a <code>matchall</code> request to your domain's search endpoint: <code>q=matchall&amp;amp;q.parser=structured&amp;amp;size=0</code>. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Information about a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773686 = newJObject()
  if DomainNames != nil:
    query_773686.add "DomainNames", DomainNames
  add(query_773686, "Action", newJString(Action))
  add(query_773686, "Version", newJString(Version))
  result = call_773685.call(nil, query_773686, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_773671(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_773672, base: "/",
    url: url_GetDescribeDomains_773673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeExpressions_773722 = ref object of OpenApiRestCall_772597
proc url_PostDescribeExpressions_773724(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeExpressions_773723(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773725 = query.getOrDefault("Action")
  valid_773725 = validateParameter(valid_773725, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_773725 != nil:
    section.add "Action", valid_773725
  var valid_773726 = query.getOrDefault("Version")
  valid_773726 = validateParameter(valid_773726, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773726 != nil:
    section.add "Version", valid_773726
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773727 = header.getOrDefault("X-Amz-Date")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Date", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-Security-Token")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Security-Token", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-Content-Sha256", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-Algorithm")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Algorithm", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Signature")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Signature", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-SignedHeaders", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-Credential")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Credential", valid_773733
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773734 = formData.getOrDefault("DomainName")
  valid_773734 = validateParameter(valid_773734, JString, required = true,
                                 default = nil)
  if valid_773734 != nil:
    section.add "DomainName", valid_773734
  var valid_773735 = formData.getOrDefault("Deployed")
  valid_773735 = validateParameter(valid_773735, JBool, required = false, default = nil)
  if valid_773735 != nil:
    section.add "Deployed", valid_773735
  var valid_773736 = formData.getOrDefault("ExpressionNames")
  valid_773736 = validateParameter(valid_773736, JArray, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "ExpressionNames", valid_773736
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773737: Call_PostDescribeExpressions_773722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773737.validator(path, query, header, formData, body)
  let scheme = call_773737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773737.url(scheme.get, call_773737.host, call_773737.base,
                         call_773737.route, valid.getOrDefault("path"))
  result = hook(call_773737, url, valid)

proc call*(call_773738: Call_PostDescribeExpressions_773722; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeExpressions";
          ExpressionNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Version: string (required)
  var query_773739 = newJObject()
  var formData_773740 = newJObject()
  add(formData_773740, "DomainName", newJString(DomainName))
  add(formData_773740, "Deployed", newJBool(Deployed))
  add(query_773739, "Action", newJString(Action))
  if ExpressionNames != nil:
    formData_773740.add "ExpressionNames", ExpressionNames
  add(query_773739, "Version", newJString(Version))
  result = call_773738.call(nil, query_773739, nil, formData_773740, nil)

var postDescribeExpressions* = Call_PostDescribeExpressions_773722(
    name: "postDescribeExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_PostDescribeExpressions_773723, base: "/",
    url: url_PostDescribeExpressions_773724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeExpressions_773704 = ref object of OpenApiRestCall_772597
proc url_GetDescribeExpressions_773706(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeExpressions_773705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_773707 = query.getOrDefault("Deployed")
  valid_773707 = validateParameter(valid_773707, JBool, required = false, default = nil)
  if valid_773707 != nil:
    section.add "Deployed", valid_773707
  var valid_773708 = query.getOrDefault("ExpressionNames")
  valid_773708 = validateParameter(valid_773708, JArray, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "ExpressionNames", valid_773708
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773709 = query.getOrDefault("Action")
  valid_773709 = validateParameter(valid_773709, JString, required = true,
                                 default = newJString("DescribeExpressions"))
  if valid_773709 != nil:
    section.add "Action", valid_773709
  var valid_773710 = query.getOrDefault("DomainName")
  valid_773710 = validateParameter(valid_773710, JString, required = true,
                                 default = nil)
  if valid_773710 != nil:
    section.add "DomainName", valid_773710
  var valid_773711 = query.getOrDefault("Version")
  valid_773711 = validateParameter(valid_773711, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773711 != nil:
    section.add "Version", valid_773711
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773712 = header.getOrDefault("X-Amz-Date")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Date", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-Security-Token")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Security-Token", valid_773713
  var valid_773714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-Content-Sha256", valid_773714
  var valid_773715 = header.getOrDefault("X-Amz-Algorithm")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Algorithm", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-Signature")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Signature", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-SignedHeaders", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-Credential")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-Credential", valid_773718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773719: Call_GetDescribeExpressions_773704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773719.validator(path, query, header, formData, body)
  let scheme = call_773719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773719.url(scheme.get, call_773719.host, call_773719.base,
                         call_773719.route, valid.getOrDefault("path"))
  result = hook(call_773719, url, valid)

proc call*(call_773720: Call_GetDescribeExpressions_773704; DomainName: string;
          Deployed: bool = false; ExpressionNames: JsonNode = nil;
          Action: string = "DescribeExpressions"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeExpressions
  ## Gets the expressions configured for the search domain. Can be limited to specific expressions by name. By default, shows all expressions and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-expressions.html" target="_blank">Configuring Expressions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   ExpressionNames: JArray
  ##                  : Limits the <code><a>DescribeExpressions</a></code> response to the specified expressions. If not specified, all expressions are shown.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773721 = newJObject()
  add(query_773721, "Deployed", newJBool(Deployed))
  if ExpressionNames != nil:
    query_773721.add "ExpressionNames", ExpressionNames
  add(query_773721, "Action", newJString(Action))
  add(query_773721, "DomainName", newJString(DomainName))
  add(query_773721, "Version", newJString(Version))
  result = call_773720.call(nil, query_773721, nil, nil, nil)

var getDescribeExpressions* = Call_GetDescribeExpressions_773704(
    name: "getDescribeExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeExpressions",
    validator: validate_GetDescribeExpressions_773705, base: "/",
    url: url_GetDescribeExpressions_773706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_773759 = ref object of OpenApiRestCall_772597
proc url_PostDescribeIndexFields_773761(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeIndexFields_773760(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773762 = query.getOrDefault("Action")
  valid_773762 = validateParameter(valid_773762, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_773762 != nil:
    section.add "Action", valid_773762
  var valid_773763 = query.getOrDefault("Version")
  valid_773763 = validateParameter(valid_773763, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773763 != nil:
    section.add "Version", valid_773763
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773764 = header.getOrDefault("X-Amz-Date")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Date", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-Security-Token")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-Security-Token", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Content-Sha256", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-Algorithm")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-Algorithm", valid_773767
  var valid_773768 = header.getOrDefault("X-Amz-Signature")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Signature", valid_773768
  var valid_773769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773769 = validateParameter(valid_773769, JString, required = false,
                                 default = nil)
  if valid_773769 != nil:
    section.add "X-Amz-SignedHeaders", valid_773769
  var valid_773770 = header.getOrDefault("X-Amz-Credential")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Credential", valid_773770
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773771 = formData.getOrDefault("DomainName")
  valid_773771 = validateParameter(valid_773771, JString, required = true,
                                 default = nil)
  if valid_773771 != nil:
    section.add "DomainName", valid_773771
  var valid_773772 = formData.getOrDefault("Deployed")
  valid_773772 = validateParameter(valid_773772, JBool, required = false, default = nil)
  if valid_773772 != nil:
    section.add "Deployed", valid_773772
  var valid_773773 = formData.getOrDefault("FieldNames")
  valid_773773 = validateParameter(valid_773773, JArray, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "FieldNames", valid_773773
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773774: Call_PostDescribeIndexFields_773759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773774.validator(path, query, header, formData, body)
  let scheme = call_773774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773774.url(scheme.get, call_773774.host, call_773774.base,
                         call_773774.route, valid.getOrDefault("path"))
  result = hook(call_773774, url, valid)

proc call*(call_773775: Call_PostDescribeIndexFields_773759; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeIndexFields";
          FieldNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Version: string (required)
  var query_773776 = newJObject()
  var formData_773777 = newJObject()
  add(formData_773777, "DomainName", newJString(DomainName))
  add(formData_773777, "Deployed", newJBool(Deployed))
  add(query_773776, "Action", newJString(Action))
  if FieldNames != nil:
    formData_773777.add "FieldNames", FieldNames
  add(query_773776, "Version", newJString(Version))
  result = call_773775.call(nil, query_773776, nil, formData_773777, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_773759(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_773760, base: "/",
    url: url_PostDescribeIndexFields_773761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_773741 = ref object of OpenApiRestCall_772597
proc url_GetDescribeIndexFields_773743(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeIndexFields_773742(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_773744 = query.getOrDefault("Deployed")
  valid_773744 = validateParameter(valid_773744, JBool, required = false, default = nil)
  if valid_773744 != nil:
    section.add "Deployed", valid_773744
  var valid_773745 = query.getOrDefault("FieldNames")
  valid_773745 = validateParameter(valid_773745, JArray, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "FieldNames", valid_773745
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773746 = query.getOrDefault("Action")
  valid_773746 = validateParameter(valid_773746, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_773746 != nil:
    section.add "Action", valid_773746
  var valid_773747 = query.getOrDefault("DomainName")
  valid_773747 = validateParameter(valid_773747, JString, required = true,
                                 default = nil)
  if valid_773747 != nil:
    section.add "DomainName", valid_773747
  var valid_773748 = query.getOrDefault("Version")
  valid_773748 = validateParameter(valid_773748, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773748 != nil:
    section.add "Version", valid_773748
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773749 = header.getOrDefault("X-Amz-Date")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Date", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-Security-Token")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Security-Token", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Content-Sha256", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-Algorithm")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Algorithm", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Signature")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Signature", valid_773753
  var valid_773754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773754 = validateParameter(valid_773754, JString, required = false,
                                 default = nil)
  if valid_773754 != nil:
    section.add "X-Amz-SignedHeaders", valid_773754
  var valid_773755 = header.getOrDefault("X-Amz-Credential")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-Credential", valid_773755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773756: Call_GetDescribeIndexFields_773741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773756.validator(path, query, header, formData, body)
  let scheme = call_773756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773756.url(scheme.get, call_773756.host, call_773756.base,
                         call_773756.route, valid.getOrDefault("path"))
  result = hook(call_773756, url, valid)

proc call*(call_773757: Call_GetDescribeIndexFields_773741; DomainName: string;
          Deployed: bool = false; FieldNames: JsonNode = nil;
          Action: string = "DescribeIndexFields"; Version: string = "2013-01-01"): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. By default, shows all fields and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-domain-info.html" target="_blank">Getting Domain Information</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   FieldNames: JArray
  ##             : A list of the index fields you want to describe. If not specified, information is returned for all configured index fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773758 = newJObject()
  add(query_773758, "Deployed", newJBool(Deployed))
  if FieldNames != nil:
    query_773758.add "FieldNames", FieldNames
  add(query_773758, "Action", newJString(Action))
  add(query_773758, "DomainName", newJString(DomainName))
  add(query_773758, "Version", newJString(Version))
  result = call_773757.call(nil, query_773758, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_773741(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_773742, base: "/",
    url: url_GetDescribeIndexFields_773743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeScalingParameters_773794 = ref object of OpenApiRestCall_772597
proc url_PostDescribeScalingParameters_773796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeScalingParameters_773795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773797 = query.getOrDefault("Action")
  valid_773797 = validateParameter(valid_773797, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_773797 != nil:
    section.add "Action", valid_773797
  var valid_773798 = query.getOrDefault("Version")
  valid_773798 = validateParameter(valid_773798, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773798 != nil:
    section.add "Version", valid_773798
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773799 = header.getOrDefault("X-Amz-Date")
  valid_773799 = validateParameter(valid_773799, JString, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "X-Amz-Date", valid_773799
  var valid_773800 = header.getOrDefault("X-Amz-Security-Token")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "X-Amz-Security-Token", valid_773800
  var valid_773801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-Content-Sha256", valid_773801
  var valid_773802 = header.getOrDefault("X-Amz-Algorithm")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-Algorithm", valid_773802
  var valid_773803 = header.getOrDefault("X-Amz-Signature")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-Signature", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-SignedHeaders", valid_773804
  var valid_773805 = header.getOrDefault("X-Amz-Credential")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-Credential", valid_773805
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773806 = formData.getOrDefault("DomainName")
  valid_773806 = validateParameter(valid_773806, JString, required = true,
                                 default = nil)
  if valid_773806 != nil:
    section.add "DomainName", valid_773806
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773807: Call_PostDescribeScalingParameters_773794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773807.validator(path, query, header, formData, body)
  let scheme = call_773807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773807.url(scheme.get, call_773807.host, call_773807.base,
                         call_773807.route, valid.getOrDefault("path"))
  result = hook(call_773807, url, valid)

proc call*(call_773808: Call_PostDescribeScalingParameters_773794;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773809 = newJObject()
  var formData_773810 = newJObject()
  add(formData_773810, "DomainName", newJString(DomainName))
  add(query_773809, "Action", newJString(Action))
  add(query_773809, "Version", newJString(Version))
  result = call_773808.call(nil, query_773809, nil, formData_773810, nil)

var postDescribeScalingParameters* = Call_PostDescribeScalingParameters_773794(
    name: "postDescribeScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_PostDescribeScalingParameters_773795, base: "/",
    url: url_PostDescribeScalingParameters_773796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeScalingParameters_773778 = ref object of OpenApiRestCall_772597
proc url_GetDescribeScalingParameters_773780(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeScalingParameters_773779(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773781 = query.getOrDefault("Action")
  valid_773781 = validateParameter(valid_773781, JString, required = true, default = newJString(
      "DescribeScalingParameters"))
  if valid_773781 != nil:
    section.add "Action", valid_773781
  var valid_773782 = query.getOrDefault("DomainName")
  valid_773782 = validateParameter(valid_773782, JString, required = true,
                                 default = nil)
  if valid_773782 != nil:
    section.add "DomainName", valid_773782
  var valid_773783 = query.getOrDefault("Version")
  valid_773783 = validateParameter(valid_773783, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773783 != nil:
    section.add "Version", valid_773783
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773784 = header.getOrDefault("X-Amz-Date")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "X-Amz-Date", valid_773784
  var valid_773785 = header.getOrDefault("X-Amz-Security-Token")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Security-Token", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Content-Sha256", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Algorithm")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Algorithm", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Signature")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Signature", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-SignedHeaders", valid_773789
  var valid_773790 = header.getOrDefault("X-Amz-Credential")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Credential", valid_773790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773791: Call_GetDescribeScalingParameters_773778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773791.validator(path, query, header, formData, body)
  let scheme = call_773791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773791.url(scheme.get, call_773791.host, call_773791.base,
                         call_773791.route, valid.getOrDefault("path"))
  result = hook(call_773791, url, valid)

proc call*(call_773792: Call_GetDescribeScalingParameters_773778;
          DomainName: string; Action: string = "DescribeScalingParameters";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeScalingParameters
  ## Gets the scaling parameters configured for a domain. A domain's scaling parameters specify the desired search instance type and replication count. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773793 = newJObject()
  add(query_773793, "Action", newJString(Action))
  add(query_773793, "DomainName", newJString(DomainName))
  add(query_773793, "Version", newJString(Version))
  result = call_773792.call(nil, query_773793, nil, nil, nil)

var getDescribeScalingParameters* = Call_GetDescribeScalingParameters_773778(
    name: "getDescribeScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeScalingParameters",
    validator: validate_GetDescribeScalingParameters_773779, base: "/",
    url: url_GetDescribeScalingParameters_773780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_773828 = ref object of OpenApiRestCall_772597
proc url_PostDescribeServiceAccessPolicies_773830(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeServiceAccessPolicies_773829(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773831 = query.getOrDefault("Action")
  valid_773831 = validateParameter(valid_773831, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_773831 != nil:
    section.add "Action", valid_773831
  var valid_773832 = query.getOrDefault("Version")
  valid_773832 = validateParameter(valid_773832, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773832 != nil:
    section.add "Version", valid_773832
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773833 = header.getOrDefault("X-Amz-Date")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-Date", valid_773833
  var valid_773834 = header.getOrDefault("X-Amz-Security-Token")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-Security-Token", valid_773834
  var valid_773835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Content-Sha256", valid_773835
  var valid_773836 = header.getOrDefault("X-Amz-Algorithm")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Algorithm", valid_773836
  var valid_773837 = header.getOrDefault("X-Amz-Signature")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "X-Amz-Signature", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-SignedHeaders", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Credential")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Credential", valid_773839
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773840 = formData.getOrDefault("DomainName")
  valid_773840 = validateParameter(valid_773840, JString, required = true,
                                 default = nil)
  if valid_773840 != nil:
    section.add "DomainName", valid_773840
  var valid_773841 = formData.getOrDefault("Deployed")
  valid_773841 = validateParameter(valid_773841, JBool, required = false, default = nil)
  if valid_773841 != nil:
    section.add "Deployed", valid_773841
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773842: Call_PostDescribeServiceAccessPolicies_773828;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773842.validator(path, query, header, formData, body)
  let scheme = call_773842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773842.url(scheme.get, call_773842.host, call_773842.base,
                         call_773842.route, valid.getOrDefault("path"))
  result = hook(call_773842, url, valid)

proc call*(call_773843: Call_PostDescribeServiceAccessPolicies_773828;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773844 = newJObject()
  var formData_773845 = newJObject()
  add(formData_773845, "DomainName", newJString(DomainName))
  add(formData_773845, "Deployed", newJBool(Deployed))
  add(query_773844, "Action", newJString(Action))
  add(query_773844, "Version", newJString(Version))
  result = call_773843.call(nil, query_773844, nil, formData_773845, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_773828(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_773829, base: "/",
    url: url_PostDescribeServiceAccessPolicies_773830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_773811 = ref object of OpenApiRestCall_772597
proc url_GetDescribeServiceAccessPolicies_773813(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeServiceAccessPolicies_773812(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  var valid_773814 = query.getOrDefault("Deployed")
  valid_773814 = validateParameter(valid_773814, JBool, required = false, default = nil)
  if valid_773814 != nil:
    section.add "Deployed", valid_773814
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773815 = query.getOrDefault("Action")
  valid_773815 = validateParameter(valid_773815, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_773815 != nil:
    section.add "Action", valid_773815
  var valid_773816 = query.getOrDefault("DomainName")
  valid_773816 = validateParameter(valid_773816, JString, required = true,
                                 default = nil)
  if valid_773816 != nil:
    section.add "DomainName", valid_773816
  var valid_773817 = query.getOrDefault("Version")
  valid_773817 = validateParameter(valid_773817, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773817 != nil:
    section.add "Version", valid_773817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773818 = header.getOrDefault("X-Amz-Date")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Date", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-Security-Token")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-Security-Token", valid_773819
  var valid_773820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Content-Sha256", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Algorithm")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Algorithm", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-Signature")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-Signature", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-SignedHeaders", valid_773823
  var valid_773824 = header.getOrDefault("X-Amz-Credential")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Credential", valid_773824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773825: Call_GetDescribeServiceAccessPolicies_773811;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773825.validator(path, query, header, formData, body)
  let scheme = call_773825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773825.url(scheme.get, call_773825.host, call_773825.base,
                         call_773825.route, valid.getOrDefault("path"))
  result = hook(call_773825, url, valid)

proc call*(call_773826: Call_GetDescribeServiceAccessPolicies_773811;
          DomainName: string; Deployed: bool = false;
          Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the access policies that control access to the domain's document and search endpoints. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773827 = newJObject()
  add(query_773827, "Deployed", newJBool(Deployed))
  add(query_773827, "Action", newJString(Action))
  add(query_773827, "DomainName", newJString(DomainName))
  add(query_773827, "Version", newJString(Version))
  result = call_773826.call(nil, query_773827, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_773811(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_773812, base: "/",
    url: url_GetDescribeServiceAccessPolicies_773813,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSuggesters_773864 = ref object of OpenApiRestCall_772597
proc url_PostDescribeSuggesters_773866(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeSuggesters_773865(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773867 = query.getOrDefault("Action")
  valid_773867 = validateParameter(valid_773867, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_773867 != nil:
    section.add "Action", valid_773867
  var valid_773868 = query.getOrDefault("Version")
  valid_773868 = validateParameter(valid_773868, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773868 != nil:
    section.add "Version", valid_773868
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773869 = header.getOrDefault("X-Amz-Date")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Date", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Security-Token")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Security-Token", valid_773870
  var valid_773871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "X-Amz-Content-Sha256", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-Algorithm")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Algorithm", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Signature")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Signature", valid_773873
  var valid_773874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773874 = validateParameter(valid_773874, JString, required = false,
                                 default = nil)
  if valid_773874 != nil:
    section.add "X-Amz-SignedHeaders", valid_773874
  var valid_773875 = header.getOrDefault("X-Amz-Credential")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "X-Amz-Credential", valid_773875
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773876 = formData.getOrDefault("DomainName")
  valid_773876 = validateParameter(valid_773876, JString, required = true,
                                 default = nil)
  if valid_773876 != nil:
    section.add "DomainName", valid_773876
  var valid_773877 = formData.getOrDefault("Deployed")
  valid_773877 = validateParameter(valid_773877, JBool, required = false, default = nil)
  if valid_773877 != nil:
    section.add "Deployed", valid_773877
  var valid_773878 = formData.getOrDefault("SuggesterNames")
  valid_773878 = validateParameter(valid_773878, JArray, required = false,
                                 default = nil)
  if valid_773878 != nil:
    section.add "SuggesterNames", valid_773878
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773879: Call_PostDescribeSuggesters_773864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773879.validator(path, query, header, formData, body)
  let scheme = call_773879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773879.url(scheme.get, call_773879.host, call_773879.base,
                         call_773879.route, valid.getOrDefault("path"))
  result = hook(call_773879, url, valid)

proc call*(call_773880: Call_PostDescribeSuggesters_773864; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeSuggesters";
          SuggesterNames: JsonNode = nil; Version: string = "2013-01-01"): Recallable =
  ## postDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  ##   Version: string (required)
  var query_773881 = newJObject()
  var formData_773882 = newJObject()
  add(formData_773882, "DomainName", newJString(DomainName))
  add(formData_773882, "Deployed", newJBool(Deployed))
  add(query_773881, "Action", newJString(Action))
  if SuggesterNames != nil:
    formData_773882.add "SuggesterNames", SuggesterNames
  add(query_773881, "Version", newJString(Version))
  result = call_773880.call(nil, query_773881, nil, formData_773882, nil)

var postDescribeSuggesters* = Call_PostDescribeSuggesters_773864(
    name: "postDescribeSuggesters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_PostDescribeSuggesters_773865, base: "/",
    url: url_PostDescribeSuggesters_773866, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSuggesters_773846 = ref object of OpenApiRestCall_772597
proc url_GetDescribeSuggesters_773848(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeSuggesters_773847(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Deployed: JBool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  section = newJObject()
  var valid_773849 = query.getOrDefault("Deployed")
  valid_773849 = validateParameter(valid_773849, JBool, required = false, default = nil)
  if valid_773849 != nil:
    section.add "Deployed", valid_773849
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773850 = query.getOrDefault("Action")
  valid_773850 = validateParameter(valid_773850, JString, required = true,
                                 default = newJString("DescribeSuggesters"))
  if valid_773850 != nil:
    section.add "Action", valid_773850
  var valid_773851 = query.getOrDefault("DomainName")
  valid_773851 = validateParameter(valid_773851, JString, required = true,
                                 default = nil)
  if valid_773851 != nil:
    section.add "DomainName", valid_773851
  var valid_773852 = query.getOrDefault("Version")
  valid_773852 = validateParameter(valid_773852, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773852 != nil:
    section.add "Version", valid_773852
  var valid_773853 = query.getOrDefault("SuggesterNames")
  valid_773853 = validateParameter(valid_773853, JArray, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "SuggesterNames", valid_773853
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773854 = header.getOrDefault("X-Amz-Date")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Date", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Security-Token")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Security-Token", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-Content-Sha256", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-Algorithm")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Algorithm", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Signature")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Signature", valid_773858
  var valid_773859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773859 = validateParameter(valid_773859, JString, required = false,
                                 default = nil)
  if valid_773859 != nil:
    section.add "X-Amz-SignedHeaders", valid_773859
  var valid_773860 = header.getOrDefault("X-Amz-Credential")
  valid_773860 = validateParameter(valid_773860, JString, required = false,
                                 default = nil)
  if valid_773860 != nil:
    section.add "X-Amz-Credential", valid_773860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773861: Call_GetDescribeSuggesters_773846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773861.validator(path, query, header, formData, body)
  let scheme = call_773861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773861.url(scheme.get, call_773861.host, call_773861.base,
                         call_773861.route, valid.getOrDefault("path"))
  result = hook(call_773861, url, valid)

proc call*(call_773862: Call_GetDescribeSuggesters_773846; DomainName: string;
          Deployed: bool = false; Action: string = "DescribeSuggesters";
          Version: string = "2013-01-01"; SuggesterNames: JsonNode = nil): Recallable =
  ## getDescribeSuggesters
  ## Gets the suggesters configured for a domain. A suggester enables you to display possible matches before users finish typing their queries. Can be limited to specific suggesters by name. By default, shows all suggesters and includes any pending changes to the configuration. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/getting-suggestions.html" target="_blank">Getting Search Suggestions</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Deployed: bool
  ##           : Whether to display the deployed configuration (<code>true</code>) or include any pending changes (<code>false</code>). Defaults to <code>false</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  ##   SuggesterNames: JArray
  ##                 : The suggesters you want to describe.
  var query_773863 = newJObject()
  add(query_773863, "Deployed", newJBool(Deployed))
  add(query_773863, "Action", newJString(Action))
  add(query_773863, "DomainName", newJString(DomainName))
  add(query_773863, "Version", newJString(Version))
  if SuggesterNames != nil:
    query_773863.add "SuggesterNames", SuggesterNames
  result = call_773862.call(nil, query_773863, nil, nil, nil)

var getDescribeSuggesters* = Call_GetDescribeSuggesters_773846(
    name: "getDescribeSuggesters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSuggesters",
    validator: validate_GetDescribeSuggesters_773847, base: "/",
    url: url_GetDescribeSuggesters_773848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_773899 = ref object of OpenApiRestCall_772597
proc url_PostIndexDocuments_773901(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostIndexDocuments_773900(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773902 = query.getOrDefault("Action")
  valid_773902 = validateParameter(valid_773902, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_773902 != nil:
    section.add "Action", valid_773902
  var valid_773903 = query.getOrDefault("Version")
  valid_773903 = validateParameter(valid_773903, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773903 != nil:
    section.add "Version", valid_773903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773904 = header.getOrDefault("X-Amz-Date")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "X-Amz-Date", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-Security-Token")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-Security-Token", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Content-Sha256", valid_773906
  var valid_773907 = header.getOrDefault("X-Amz-Algorithm")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-Algorithm", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-Signature")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-Signature", valid_773908
  var valid_773909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = nil)
  if valid_773909 != nil:
    section.add "X-Amz-SignedHeaders", valid_773909
  var valid_773910 = header.getOrDefault("X-Amz-Credential")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Credential", valid_773910
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773911 = formData.getOrDefault("DomainName")
  valid_773911 = validateParameter(valid_773911, JString, required = true,
                                 default = nil)
  if valid_773911 != nil:
    section.add "DomainName", valid_773911
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773912: Call_PostIndexDocuments_773899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_773912.validator(path, query, header, formData, body)
  let scheme = call_773912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773912.url(scheme.get, call_773912.host, call_773912.base,
                         call_773912.route, valid.getOrDefault("path"))
  result = hook(call_773912, url, valid)

proc call*(call_773913: Call_PostIndexDocuments_773899; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773914 = newJObject()
  var formData_773915 = newJObject()
  add(formData_773915, "DomainName", newJString(DomainName))
  add(query_773914, "Action", newJString(Action))
  add(query_773914, "Version", newJString(Version))
  result = call_773913.call(nil, query_773914, nil, formData_773915, nil)

var postIndexDocuments* = Call_PostIndexDocuments_773899(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_773900, base: "/",
    url: url_PostIndexDocuments_773901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_773883 = ref object of OpenApiRestCall_772597
proc url_GetIndexDocuments_773885(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetIndexDocuments_773884(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773886 = query.getOrDefault("Action")
  valid_773886 = validateParameter(valid_773886, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_773886 != nil:
    section.add "Action", valid_773886
  var valid_773887 = query.getOrDefault("DomainName")
  valid_773887 = validateParameter(valid_773887, JString, required = true,
                                 default = nil)
  if valid_773887 != nil:
    section.add "DomainName", valid_773887
  var valid_773888 = query.getOrDefault("Version")
  valid_773888 = validateParameter(valid_773888, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773888 != nil:
    section.add "Version", valid_773888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773889 = header.getOrDefault("X-Amz-Date")
  valid_773889 = validateParameter(valid_773889, JString, required = false,
                                 default = nil)
  if valid_773889 != nil:
    section.add "X-Amz-Date", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Security-Token")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Security-Token", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Content-Sha256", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-Algorithm")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-Algorithm", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-Signature")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Signature", valid_773893
  var valid_773894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773894 = validateParameter(valid_773894, JString, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "X-Amz-SignedHeaders", valid_773894
  var valid_773895 = header.getOrDefault("X-Amz-Credential")
  valid_773895 = validateParameter(valid_773895, JString, required = false,
                                 default = nil)
  if valid_773895 != nil:
    section.add "X-Amz-Credential", valid_773895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773896: Call_GetIndexDocuments_773883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ## 
  let valid = call_773896.validator(path, query, header, formData, body)
  let scheme = call_773896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773896.url(scheme.get, call_773896.host, call_773896.base,
                         call_773896.route, valid.getOrDefault("path"))
  result = hook(call_773896, url, valid)

proc call*(call_773897: Call_GetIndexDocuments_773883; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2013-01-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest indexing options. This operation must be invoked to activate options whose <a>OptionStatus</a> is <code>RequiresIndexDocuments</code>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773898 = newJObject()
  add(query_773898, "Action", newJString(Action))
  add(query_773898, "DomainName", newJString(DomainName))
  add(query_773898, "Version", newJString(Version))
  result = call_773897.call(nil, query_773898, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_773883(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_773884,
    base: "/", url: url_GetIndexDocuments_773885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListDomainNames_773931 = ref object of OpenApiRestCall_772597
proc url_PostListDomainNames_773933(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListDomainNames_773932(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all search domains owned by an account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773934 = query.getOrDefault("Action")
  valid_773934 = validateParameter(valid_773934, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_773934 != nil:
    section.add "Action", valid_773934
  var valid_773935 = query.getOrDefault("Version")
  valid_773935 = validateParameter(valid_773935, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773935 != nil:
    section.add "Version", valid_773935
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773936 = header.getOrDefault("X-Amz-Date")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "X-Amz-Date", valid_773936
  var valid_773937 = header.getOrDefault("X-Amz-Security-Token")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "X-Amz-Security-Token", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-Content-Sha256", valid_773938
  var valid_773939 = header.getOrDefault("X-Amz-Algorithm")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Algorithm", valid_773939
  var valid_773940 = header.getOrDefault("X-Amz-Signature")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-Signature", valid_773940
  var valid_773941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-SignedHeaders", valid_773941
  var valid_773942 = header.getOrDefault("X-Amz-Credential")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Credential", valid_773942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773943: Call_PostListDomainNames_773931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_773943.validator(path, query, header, formData, body)
  let scheme = call_773943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773943.url(scheme.get, call_773943.host, call_773943.base,
                         call_773943.route, valid.getOrDefault("path"))
  result = hook(call_773943, url, valid)

proc call*(call_773944: Call_PostListDomainNames_773931;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## postListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773945 = newJObject()
  add(query_773945, "Action", newJString(Action))
  add(query_773945, "Version", newJString(Version))
  result = call_773944.call(nil, query_773945, nil, nil, nil)

var postListDomainNames* = Call_PostListDomainNames_773931(
    name: "postListDomainNames", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_PostListDomainNames_773932, base: "/",
    url: url_PostListDomainNames_773933, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListDomainNames_773916 = ref object of OpenApiRestCall_772597
proc url_GetListDomainNames_773918(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListDomainNames_773917(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists all search domains owned by an account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773919 = query.getOrDefault("Action")
  valid_773919 = validateParameter(valid_773919, JString, required = true,
                                 default = newJString("ListDomainNames"))
  if valid_773919 != nil:
    section.add "Action", valid_773919
  var valid_773920 = query.getOrDefault("Version")
  valid_773920 = validateParameter(valid_773920, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773920 != nil:
    section.add "Version", valid_773920
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773921 = header.getOrDefault("X-Amz-Date")
  valid_773921 = validateParameter(valid_773921, JString, required = false,
                                 default = nil)
  if valid_773921 != nil:
    section.add "X-Amz-Date", valid_773921
  var valid_773922 = header.getOrDefault("X-Amz-Security-Token")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-Security-Token", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-Content-Sha256", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-Algorithm")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-Algorithm", valid_773924
  var valid_773925 = header.getOrDefault("X-Amz-Signature")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-Signature", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-SignedHeaders", valid_773926
  var valid_773927 = header.getOrDefault("X-Amz-Credential")
  valid_773927 = validateParameter(valid_773927, JString, required = false,
                                 default = nil)
  if valid_773927 != nil:
    section.add "X-Amz-Credential", valid_773927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773928: Call_GetListDomainNames_773916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all search domains owned by an account.
  ## 
  let valid = call_773928.validator(path, query, header, formData, body)
  let scheme = call_773928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773928.url(scheme.get, call_773928.host, call_773928.base,
                         call_773928.route, valid.getOrDefault("path"))
  result = hook(call_773928, url, valid)

proc call*(call_773929: Call_GetListDomainNames_773916;
          Action: string = "ListDomainNames"; Version: string = "2013-01-01"): Recallable =
  ## getListDomainNames
  ## Lists all search domains owned by an account.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773930 = newJObject()
  add(query_773930, "Action", newJString(Action))
  add(query_773930, "Version", newJString(Version))
  result = call_773929.call(nil, query_773930, nil, nil, nil)

var getListDomainNames* = Call_GetListDomainNames_773916(
    name: "getListDomainNames", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=ListDomainNames",
    validator: validate_GetListDomainNames_773917, base: "/",
    url: url_GetListDomainNames_773918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_773963 = ref object of OpenApiRestCall_772597
proc url_PostUpdateAvailabilityOptions_773965(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateAvailabilityOptions_773964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773966 = query.getOrDefault("Action")
  valid_773966 = validateParameter(valid_773966, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_773966 != nil:
    section.add "Action", valid_773966
  var valid_773967 = query.getOrDefault("Version")
  valid_773967 = validateParameter(valid_773967, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773967 != nil:
    section.add "Version", valid_773967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773968 = header.getOrDefault("X-Amz-Date")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-Date", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Security-Token")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Security-Token", valid_773969
  var valid_773970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773970 = validateParameter(valid_773970, JString, required = false,
                                 default = nil)
  if valid_773970 != nil:
    section.add "X-Amz-Content-Sha256", valid_773970
  var valid_773971 = header.getOrDefault("X-Amz-Algorithm")
  valid_773971 = validateParameter(valid_773971, JString, required = false,
                                 default = nil)
  if valid_773971 != nil:
    section.add "X-Amz-Algorithm", valid_773971
  var valid_773972 = header.getOrDefault("X-Amz-Signature")
  valid_773972 = validateParameter(valid_773972, JString, required = false,
                                 default = nil)
  if valid_773972 != nil:
    section.add "X-Amz-Signature", valid_773972
  var valid_773973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773973 = validateParameter(valid_773973, JString, required = false,
                                 default = nil)
  if valid_773973 != nil:
    section.add "X-Amz-SignedHeaders", valid_773973
  var valid_773974 = header.getOrDefault("X-Amz-Credential")
  valid_773974 = validateParameter(valid_773974, JString, required = false,
                                 default = nil)
  if valid_773974 != nil:
    section.add "X-Amz-Credential", valid_773974
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773975 = formData.getOrDefault("DomainName")
  valid_773975 = validateParameter(valid_773975, JString, required = true,
                                 default = nil)
  if valid_773975 != nil:
    section.add "DomainName", valid_773975
  var valid_773976 = formData.getOrDefault("MultiAZ")
  valid_773976 = validateParameter(valid_773976, JBool, required = true, default = nil)
  if valid_773976 != nil:
    section.add "MultiAZ", valid_773976
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773977: Call_PostUpdateAvailabilityOptions_773963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773977.validator(path, query, header, formData, body)
  let scheme = call_773977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773977.url(scheme.get, call_773977.host, call_773977.base,
                         call_773977.route, valid.getOrDefault("path"))
  result = hook(call_773977, url, valid)

proc call*(call_773978: Call_PostUpdateAvailabilityOptions_773963;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773979 = newJObject()
  var formData_773980 = newJObject()
  add(formData_773980, "DomainName", newJString(DomainName))
  add(formData_773980, "MultiAZ", newJBool(MultiAZ))
  add(query_773979, "Action", newJString(Action))
  add(query_773979, "Version", newJString(Version))
  result = call_773978.call(nil, query_773979, nil, formData_773980, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_773963(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_773964, base: "/",
    url: url_PostUpdateAvailabilityOptions_773965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_773946 = ref object of OpenApiRestCall_772597
proc url_GetUpdateAvailabilityOptions_773948(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateAvailabilityOptions_773947(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `MultiAZ` field"
  var valid_773949 = query.getOrDefault("MultiAZ")
  valid_773949 = validateParameter(valid_773949, JBool, required = true, default = nil)
  if valid_773949 != nil:
    section.add "MultiAZ", valid_773949
  var valid_773950 = query.getOrDefault("Action")
  valid_773950 = validateParameter(valid_773950, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_773950 != nil:
    section.add "Action", valid_773950
  var valid_773951 = query.getOrDefault("DomainName")
  valid_773951 = validateParameter(valid_773951, JString, required = true,
                                 default = nil)
  if valid_773951 != nil:
    section.add "DomainName", valid_773951
  var valid_773952 = query.getOrDefault("Version")
  valid_773952 = validateParameter(valid_773952, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773952 != nil:
    section.add "Version", valid_773952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773953 = header.getOrDefault("X-Amz-Date")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-Date", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Security-Token")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Security-Token", valid_773954
  var valid_773955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "X-Amz-Content-Sha256", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-Algorithm")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Algorithm", valid_773956
  var valid_773957 = header.getOrDefault("X-Amz-Signature")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Signature", valid_773957
  var valid_773958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773958 = validateParameter(valid_773958, JString, required = false,
                                 default = nil)
  if valid_773958 != nil:
    section.add "X-Amz-SignedHeaders", valid_773958
  var valid_773959 = header.getOrDefault("X-Amz-Credential")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "X-Amz-Credential", valid_773959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773960: Call_GetUpdateAvailabilityOptions_773946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773960.validator(path, query, header, formData, body)
  let scheme = call_773960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773960.url(scheme.get, call_773960.host, call_773960.base,
                         call_773960.route, valid.getOrDefault("path"))
  result = hook(call_773960, url, valid)

proc call*(call_773961: Call_GetUpdateAvailabilityOptions_773946; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_773962 = newJObject()
  add(query_773962, "MultiAZ", newJBool(MultiAZ))
  add(query_773962, "Action", newJString(Action))
  add(query_773962, "DomainName", newJString(DomainName))
  add(query_773962, "Version", newJString(Version))
  result = call_773961.call(nil, query_773962, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_773946(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_773947, base: "/",
    url: url_GetUpdateAvailabilityOptions_773948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateScalingParameters_774000 = ref object of OpenApiRestCall_772597
proc url_PostUpdateScalingParameters_774002(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateScalingParameters_774001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774003 = query.getOrDefault("Action")
  valid_774003 = validateParameter(valid_774003, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_774003 != nil:
    section.add "Action", valid_774003
  var valid_774004 = query.getOrDefault("Version")
  valid_774004 = validateParameter(valid_774004, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_774004 != nil:
    section.add "Version", valid_774004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774005 = header.getOrDefault("X-Amz-Date")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-Date", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-Security-Token")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-Security-Token", valid_774006
  var valid_774007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-Content-Sha256", valid_774007
  var valid_774008 = header.getOrDefault("X-Amz-Algorithm")
  valid_774008 = validateParameter(valid_774008, JString, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "X-Amz-Algorithm", valid_774008
  var valid_774009 = header.getOrDefault("X-Amz-Signature")
  valid_774009 = validateParameter(valid_774009, JString, required = false,
                                 default = nil)
  if valid_774009 != nil:
    section.add "X-Amz-Signature", valid_774009
  var valid_774010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774010 = validateParameter(valid_774010, JString, required = false,
                                 default = nil)
  if valid_774010 != nil:
    section.add "X-Amz-SignedHeaders", valid_774010
  var valid_774011 = header.getOrDefault("X-Amz-Credential")
  valid_774011 = validateParameter(valid_774011, JString, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "X-Amz-Credential", valid_774011
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_774012 = formData.getOrDefault("DomainName")
  valid_774012 = validateParameter(valid_774012, JString, required = true,
                                 default = nil)
  if valid_774012 != nil:
    section.add "DomainName", valid_774012
  var valid_774013 = formData.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_774013
  var valid_774014 = formData.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_774014 = validateParameter(valid_774014, JString, required = false,
                                 default = nil)
  if valid_774014 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_774014
  var valid_774015 = formData.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_774015
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774016: Call_PostUpdateScalingParameters_774000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_774016.validator(path, query, header, formData, body)
  let scheme = call_774016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774016.url(scheme.get, call_774016.host, call_774016.base,
                         call_774016.route, valid.getOrDefault("path"))
  result = hook(call_774016, url, valid)

proc call*(call_774017: Call_PostUpdateScalingParameters_774000;
          DomainName: string; ScalingParametersDesiredPartitionCount: string = "";
          Action: string = "UpdateScalingParameters";
          ScalingParametersDesiredReplicationCount: string = "";
          ScalingParametersDesiredInstanceType: string = "";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   Action: string (required)
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  ##   Version: string (required)
  var query_774018 = newJObject()
  var formData_774019 = newJObject()
  add(formData_774019, "DomainName", newJString(DomainName))
  add(formData_774019, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_774018, "Action", newJString(Action))
  add(formData_774019, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(formData_774019, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  add(query_774018, "Version", newJString(Version))
  result = call_774017.call(nil, query_774018, nil, formData_774019, nil)

var postUpdateScalingParameters* = Call_PostUpdateScalingParameters_774000(
    name: "postUpdateScalingParameters", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_PostUpdateScalingParameters_774001, base: "/",
    url: url_PostUpdateScalingParameters_774002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateScalingParameters_773981 = ref object of OpenApiRestCall_772597
proc url_GetUpdateScalingParameters_773983(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateScalingParameters_773982(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ScalingParameters.DesiredReplicationCount: JString
  ##                                            : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParameters.DesiredPartitionCount: JString
  ##                                          : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  ##   ScalingParameters.DesiredInstanceType: JString
  ##                                        : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  section = newJObject()
  var valid_773984 = query.getOrDefault("ScalingParameters.DesiredReplicationCount")
  valid_773984 = validateParameter(valid_773984, JString, required = false,
                                 default = nil)
  if valid_773984 != nil:
    section.add "ScalingParameters.DesiredReplicationCount", valid_773984
  var valid_773985 = query.getOrDefault("ScalingParameters.DesiredPartitionCount")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "ScalingParameters.DesiredPartitionCount", valid_773985
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773986 = query.getOrDefault("Action")
  valid_773986 = validateParameter(valid_773986, JString, required = true, default = newJString(
      "UpdateScalingParameters"))
  if valid_773986 != nil:
    section.add "Action", valid_773986
  var valid_773987 = query.getOrDefault("DomainName")
  valid_773987 = validateParameter(valid_773987, JString, required = true,
                                 default = nil)
  if valid_773987 != nil:
    section.add "DomainName", valid_773987
  var valid_773988 = query.getOrDefault("Version")
  valid_773988 = validateParameter(valid_773988, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_773988 != nil:
    section.add "Version", valid_773988
  var valid_773989 = query.getOrDefault("ScalingParameters.DesiredInstanceType")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "ScalingParameters.DesiredInstanceType", valid_773989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773990 = header.getOrDefault("X-Amz-Date")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-Date", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-Security-Token")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-Security-Token", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Content-Sha256", valid_773992
  var valid_773993 = header.getOrDefault("X-Amz-Algorithm")
  valid_773993 = validateParameter(valid_773993, JString, required = false,
                                 default = nil)
  if valid_773993 != nil:
    section.add "X-Amz-Algorithm", valid_773993
  var valid_773994 = header.getOrDefault("X-Amz-Signature")
  valid_773994 = validateParameter(valid_773994, JString, required = false,
                                 default = nil)
  if valid_773994 != nil:
    section.add "X-Amz-Signature", valid_773994
  var valid_773995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "X-Amz-SignedHeaders", valid_773995
  var valid_773996 = header.getOrDefault("X-Amz-Credential")
  valid_773996 = validateParameter(valid_773996, JString, required = false,
                                 default = nil)
  if valid_773996 != nil:
    section.add "X-Amz-Credential", valid_773996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773997: Call_GetUpdateScalingParameters_773981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ## 
  let valid = call_773997.validator(path, query, header, formData, body)
  let scheme = call_773997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773997.url(scheme.get, call_773997.host, call_773997.base,
                         call_773997.route, valid.getOrDefault("path"))
  result = hook(call_773997, url, valid)

proc call*(call_773998: Call_GetUpdateScalingParameters_773981; DomainName: string;
          ScalingParametersDesiredReplicationCount: string = "";
          ScalingParametersDesiredPartitionCount: string = "";
          Action: string = "UpdateScalingParameters";
          Version: string = "2013-01-01";
          ScalingParametersDesiredInstanceType: string = ""): Recallable =
  ## getUpdateScalingParameters
  ## Configures scaling parameters for a domain. A domain's scaling parameters specify the desired search instance type and replication count. Amazon CloudSearch will still automatically scale your domain based on the volume of data and traffic, but not below the desired instance type and replication count. If the Multi-AZ option is enabled, these values control the resources used per Availability Zone. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-scaling-options.html" target="_blank">Configuring Scaling Options</a> in the <i>Amazon CloudSearch Developer Guide</i>. 
  ##   ScalingParametersDesiredReplicationCount: string
  ##                                           : The desired instance type and desired number of replicas of each index partition.
  ## The number of replicas you want to preconfigure for each index partition.
  ##   ScalingParametersDesiredPartitionCount: string
  ##                                         : The desired instance type and desired number of replicas of each index partition.
  ## The number of partitions you want to preconfigure for your domain. Only valid when you select <code>m2.2xlarge</code> as the desired instance type.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  ##   ScalingParametersDesiredInstanceType: string
  ##                                       : The desired instance type and desired number of replicas of each index partition.
  ## The instance type that you want to preconfigure for your domain. For example, <code>search.m1.small</code>.
  var query_773999 = newJObject()
  add(query_773999, "ScalingParameters.DesiredReplicationCount",
      newJString(ScalingParametersDesiredReplicationCount))
  add(query_773999, "ScalingParameters.DesiredPartitionCount",
      newJString(ScalingParametersDesiredPartitionCount))
  add(query_773999, "Action", newJString(Action))
  add(query_773999, "DomainName", newJString(DomainName))
  add(query_773999, "Version", newJString(Version))
  add(query_773999, "ScalingParameters.DesiredInstanceType",
      newJString(ScalingParametersDesiredInstanceType))
  result = call_773998.call(nil, query_773999, nil, nil, nil)

var getUpdateScalingParameters* = Call_GetUpdateScalingParameters_773981(
    name: "getUpdateScalingParameters", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateScalingParameters",
    validator: validate_GetUpdateScalingParameters_773982, base: "/",
    url: url_GetUpdateScalingParameters_773983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_774037 = ref object of OpenApiRestCall_772597
proc url_PostUpdateServiceAccessPolicies_774039(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateServiceAccessPolicies_774038(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774040 = query.getOrDefault("Action")
  valid_774040 = validateParameter(valid_774040, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_774040 != nil:
    section.add "Action", valid_774040
  var valid_774041 = query.getOrDefault("Version")
  valid_774041 = validateParameter(valid_774041, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_774041 != nil:
    section.add "Version", valid_774041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774042 = header.getOrDefault("X-Amz-Date")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Date", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Security-Token")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Security-Token", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-Content-Sha256", valid_774044
  var valid_774045 = header.getOrDefault("X-Amz-Algorithm")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-Algorithm", valid_774045
  var valid_774046 = header.getOrDefault("X-Amz-Signature")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "X-Amz-Signature", valid_774046
  var valid_774047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774047 = validateParameter(valid_774047, JString, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "X-Amz-SignedHeaders", valid_774047
  var valid_774048 = header.getOrDefault("X-Amz-Credential")
  valid_774048 = validateParameter(valid_774048, JString, required = false,
                                 default = nil)
  if valid_774048 != nil:
    section.add "X-Amz-Credential", valid_774048
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_774049 = formData.getOrDefault("DomainName")
  valid_774049 = validateParameter(valid_774049, JString, required = true,
                                 default = nil)
  if valid_774049 != nil:
    section.add "DomainName", valid_774049
  var valid_774050 = formData.getOrDefault("AccessPolicies")
  valid_774050 = validateParameter(valid_774050, JString, required = true,
                                 default = nil)
  if valid_774050 != nil:
    section.add "AccessPolicies", valid_774050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774051: Call_PostUpdateServiceAccessPolicies_774037;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_774051.validator(path, query, header, formData, body)
  let scheme = call_774051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774051.url(scheme.get, call_774051.host, call_774051.base,
                         call_774051.route, valid.getOrDefault("path"))
  result = hook(call_774051, url, valid)

proc call*(call_774052: Call_PostUpdateServiceAccessPolicies_774037;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774053 = newJObject()
  var formData_774054 = newJObject()
  add(formData_774054, "DomainName", newJString(DomainName))
  add(formData_774054, "AccessPolicies", newJString(AccessPolicies))
  add(query_774053, "Action", newJString(Action))
  add(query_774053, "Version", newJString(Version))
  result = call_774052.call(nil, query_774053, nil, formData_774054, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_774037(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_774038, base: "/",
    url: url_PostUpdateServiceAccessPolicies_774039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_774020 = ref object of OpenApiRestCall_772597
proc url_GetUpdateServiceAccessPolicies_774022(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateServiceAccessPolicies_774021(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774023 = query.getOrDefault("Action")
  valid_774023 = validateParameter(valid_774023, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_774023 != nil:
    section.add "Action", valid_774023
  var valid_774024 = query.getOrDefault("AccessPolicies")
  valid_774024 = validateParameter(valid_774024, JString, required = true,
                                 default = nil)
  if valid_774024 != nil:
    section.add "AccessPolicies", valid_774024
  var valid_774025 = query.getOrDefault("DomainName")
  valid_774025 = validateParameter(valid_774025, JString, required = true,
                                 default = nil)
  if valid_774025 != nil:
    section.add "DomainName", valid_774025
  var valid_774026 = query.getOrDefault("Version")
  valid_774026 = validateParameter(valid_774026, JString, required = true,
                                 default = newJString("2013-01-01"))
  if valid_774026 != nil:
    section.add "Version", valid_774026
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774027 = header.getOrDefault("X-Amz-Date")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Date", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Security-Token")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Security-Token", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Content-Sha256", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-Algorithm")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-Algorithm", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-Signature")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-Signature", valid_774031
  var valid_774032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774032 = validateParameter(valid_774032, JString, required = false,
                                 default = nil)
  if valid_774032 != nil:
    section.add "X-Amz-SignedHeaders", valid_774032
  var valid_774033 = header.getOrDefault("X-Amz-Credential")
  valid_774033 = validateParameter(valid_774033, JString, required = false,
                                 default = nil)
  if valid_774033 != nil:
    section.add "X-Amz-Credential", valid_774033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774034: Call_GetUpdateServiceAccessPolicies_774020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ## 
  let valid = call_774034.validator(path, query, header, formData, body)
  let scheme = call_774034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774034.url(scheme.get, call_774034.host, call_774034.base,
                         call_774034.route, valid.getOrDefault("path"))
  result = hook(call_774034, url, valid)

proc call*(call_774035: Call_GetUpdateServiceAccessPolicies_774020;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2013-01-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the access rules that control access to the domain's document and search endpoints. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank"> Configuring Access for an Amazon CloudSearch Domain</a>.
  ##   Action: string (required)
  ##   AccessPolicies: string (required)
  ##                 : Access rules for a domain's document or search service endpoints. For more information, see <a 
  ## href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-access.html" target="_blank">Configuring Access for a Search Domain</a> in the <i>Amazon CloudSearch Developer Guide</i>. The maximum size of a policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   Version: string (required)
  var query_774036 = newJObject()
  add(query_774036, "Action", newJString(Action))
  add(query_774036, "AccessPolicies", newJString(AccessPolicies))
  add(query_774036, "DomainName", newJString(DomainName))
  add(query_774036, "Version", newJString(Version))
  result = call_774035.call(nil, query_774036, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_774020(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_774021, base: "/",
    url: url_GetUpdateServiceAccessPolicies_774022,
    schemes: {Scheme.Https, Scheme.Http})
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
