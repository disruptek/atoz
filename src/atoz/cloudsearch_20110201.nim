
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2011-02-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region">Regions and Endpoints</a>.</p>
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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostCreateDomain_613267 = ref object of OpenApiRestCall_612658
proc url_PostCreateDomain_613269(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_613268(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613270 = query.getOrDefault("Action")
  valid_613270 = validateParameter(valid_613270, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_613270 != nil:
    section.add "Action", valid_613270
  var valid_613271 = query.getOrDefault("Version")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613271 != nil:
    section.add "Version", valid_613271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613272 = header.getOrDefault("X-Amz-Signature")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Signature", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Content-Sha256", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Date")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Date", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Credential")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Credential", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Security-Token")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Security-Token", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Algorithm")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Algorithm", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-SignedHeaders", valid_613278
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613279 = formData.getOrDefault("DomainName")
  valid_613279 = validateParameter(valid_613279, JString, required = true,
                                 default = nil)
  if valid_613279 != nil:
    section.add "DomainName", valid_613279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613280: Call_PostCreateDomain_613267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_613280.validator(path, query, header, formData, body)
  let scheme = call_613280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613280.url(scheme.get, call_613280.host, call_613280.base,
                         call_613280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613280, url, valid)

proc call*(call_613281: Call_PostCreateDomain_613267; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613282 = newJObject()
  var formData_613283 = newJObject()
  add(formData_613283, "DomainName", newJString(DomainName))
  add(query_613282, "Action", newJString(Action))
  add(query_613282, "Version", newJString(Version))
  result = call_613281.call(nil, query_613282, nil, formData_613283, nil)

var postCreateDomain* = Call_PostCreateDomain_613267(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_613268,
    base: "/", url: url_PostCreateDomain_613269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_612996 = ref object of OpenApiRestCall_612658
proc url_GetCreateDomain_612998(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_612997(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613110 = query.getOrDefault("DomainName")
  valid_613110 = validateParameter(valid_613110, JString, required = true,
                                 default = nil)
  if valid_613110 != nil:
    section.add "DomainName", valid_613110
  var valid_613124 = query.getOrDefault("Action")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_613124 != nil:
    section.add "Action", valid_613124
  var valid_613125 = query.getOrDefault("Version")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613125 != nil:
    section.add "Version", valid_613125
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613126 = header.getOrDefault("X-Amz-Signature")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Signature", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Content-Sha256", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Date")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Date", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Credential")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Credential", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Security-Token")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Security-Token", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Algorithm")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Algorithm", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-SignedHeaders", valid_613132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613155: Call_GetCreateDomain_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_GetCreateDomain_612996; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613227 = newJObject()
  add(query_613227, "DomainName", newJString(DomainName))
  add(query_613227, "Action", newJString(Action))
  add(query_613227, "Version", newJString(Version))
  result = call_613226.call(nil, query_613227, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_612996(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_612997,
    base: "/", url: url_GetCreateDomain_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_613306 = ref object of OpenApiRestCall_612658
proc url_PostDefineIndexField_613308(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineIndexField_613307(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613309 = query.getOrDefault("Action")
  valid_613309 = validateParameter(valid_613309, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_613309 != nil:
    section.add "Action", valid_613309
  var valid_613310 = query.getOrDefault("Version")
  valid_613310 = validateParameter(valid_613310, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613310 != nil:
    section.add "Version", valid_613310
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613311 = header.getOrDefault("X-Amz-Signature")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Signature", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Content-Sha256", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Date")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Date", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Credential")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Credential", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Security-Token")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Security-Token", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Algorithm")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Algorithm", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-SignedHeaders", valid_613317
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  var valid_613318 = formData.getOrDefault("IndexField.UIntOptions")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "IndexField.UIntOptions", valid_613318
  var valid_613319 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_613319 = validateParameter(valid_613319, JArray, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "IndexField.SourceAttributes", valid_613319
  var valid_613320 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "IndexField.IndexFieldType", valid_613320
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613321 = formData.getOrDefault("DomainName")
  valid_613321 = validateParameter(valid_613321, JString, required = true,
                                 default = nil)
  if valid_613321 != nil:
    section.add "DomainName", valid_613321
  var valid_613322 = formData.getOrDefault("IndexField.TextOptions")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "IndexField.TextOptions", valid_613322
  var valid_613323 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "IndexField.LiteralOptions", valid_613323
  var valid_613324 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "IndexField.IndexFieldName", valid_613324
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613325: Call_PostDefineIndexField_613306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_613325.validator(path, query, header, formData, body)
  let scheme = call_613325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613325.url(scheme.get, call_613325.host, call_613325.base,
                         call_613325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613325, url, valid)

proc call*(call_613326: Call_PostDefineIndexField_613306; DomainName: string;
          IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          IndexFieldIndexFieldType: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; Version: string = "2011-02-01"): Recallable =
  ## postDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_613327 = newJObject()
  var formData_613328 = newJObject()
  add(formData_613328, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    formData_613328.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(formData_613328, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_613328, "DomainName", newJString(DomainName))
  add(formData_613328, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_613328, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_613327, "Action", newJString(Action))
  add(formData_613328, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_613327, "Version", newJString(Version))
  result = call_613326.call(nil, query_613327, nil, formData_613328, nil)

var postDefineIndexField* = Call_PostDefineIndexField_613306(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_613307, base: "/",
    url: url_PostDefineIndexField_613308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_613284 = ref object of OpenApiRestCall_612658
proc url_GetDefineIndexField_613286(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineIndexField_613285(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: JString (required)
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: JString (required)
  section = newJObject()
  var valid_613287 = query.getOrDefault("IndexField.TextOptions")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "IndexField.TextOptions", valid_613287
  var valid_613288 = query.getOrDefault("IndexField.IndexFieldType")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "IndexField.IndexFieldType", valid_613288
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613289 = query.getOrDefault("DomainName")
  valid_613289 = validateParameter(valid_613289, JString, required = true,
                                 default = nil)
  if valid_613289 != nil:
    section.add "DomainName", valid_613289
  var valid_613290 = query.getOrDefault("IndexField.IndexFieldName")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "IndexField.IndexFieldName", valid_613290
  var valid_613291 = query.getOrDefault("IndexField.UIntOptions")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "IndexField.UIntOptions", valid_613291
  var valid_613292 = query.getOrDefault("IndexField.SourceAttributes")
  valid_613292 = validateParameter(valid_613292, JArray, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "IndexField.SourceAttributes", valid_613292
  var valid_613293 = query.getOrDefault("Action")
  valid_613293 = validateParameter(valid_613293, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_613293 != nil:
    section.add "Action", valid_613293
  var valid_613294 = query.getOrDefault("IndexField.LiteralOptions")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "IndexField.LiteralOptions", valid_613294
  var valid_613295 = query.getOrDefault("Version")
  valid_613295 = validateParameter(valid_613295, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613295 != nil:
    section.add "Version", valid_613295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613296 = header.getOrDefault("X-Amz-Signature")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Signature", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Content-Sha256", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Date")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Date", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Credential")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Credential", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Security-Token")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Security-Token", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Algorithm")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Algorithm", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-SignedHeaders", valid_613302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613303: Call_GetDefineIndexField_613284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_613303.validator(path, query, header, formData, body)
  let scheme = call_613303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613303.url(scheme.get, call_613303.host, call_613303.base,
                         call_613303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613303, url, valid)

proc call*(call_613304: Call_GetDefineIndexField_613284; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldIndexFieldType: string = "";
          IndexFieldIndexFieldName: string = ""; IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          Action: string = "DefineIndexField";
          IndexFieldLiteralOptions: string = ""; Version: string = "2011-02-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: string (required)
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: string (required)
  var query_613305 = newJObject()
  add(query_613305, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_613305, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_613305, "DomainName", newJString(DomainName))
  add(query_613305, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_613305, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    query_613305.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_613305, "Action", newJString(Action))
  add(query_613305, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_613305, "Version", newJString(Version))
  result = call_613304.call(nil, query_613305, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_613284(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_613285, base: "/",
    url: url_GetDefineIndexField_613286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_613347 = ref object of OpenApiRestCall_612658
proc url_PostDefineRankExpression_613349(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineRankExpression_613348(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613350 = query.getOrDefault("Action")
  valid_613350 = validateParameter(valid_613350, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_613350 != nil:
    section.add "Action", valid_613350
  var valid_613351 = query.getOrDefault("Version")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613351 != nil:
    section.add "Version", valid_613351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613352 = header.getOrDefault("X-Amz-Signature")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Signature", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Content-Sha256", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Date")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Date", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Credential")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Credential", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Security-Token")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Security-Token", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Algorithm")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Algorithm", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-SignedHeaders", valid_613358
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_613359 = formData.getOrDefault("RankExpression.RankName")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "RankExpression.RankName", valid_613359
  var valid_613360 = formData.getOrDefault("RankExpression.RankExpression")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "RankExpression.RankExpression", valid_613360
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613361 = formData.getOrDefault("DomainName")
  valid_613361 = validateParameter(valid_613361, JString, required = true,
                                 default = nil)
  if valid_613361 != nil:
    section.add "DomainName", valid_613361
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613362: Call_PostDefineRankExpression_613347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_613362.validator(path, query, header, formData, body)
  let scheme = call_613362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613362.url(scheme.get, call_613362.host, call_613362.base,
                         call_613362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613362, url, valid)

proc call*(call_613363: Call_PostDefineRankExpression_613347; DomainName: string;
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = "";
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01"): Recallable =
  ## postDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613364 = newJObject()
  var formData_613365 = newJObject()
  add(formData_613365, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_613365, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(formData_613365, "DomainName", newJString(DomainName))
  add(query_613364, "Action", newJString(Action))
  add(query_613364, "Version", newJString(Version))
  result = call_613363.call(nil, query_613364, nil, formData_613365, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_613347(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_613348, base: "/",
    url: url_PostDefineRankExpression_613349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_613329 = ref object of OpenApiRestCall_612658
proc url_GetDefineRankExpression_613331(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineRankExpression_613330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613332 = query.getOrDefault("DomainName")
  valid_613332 = validateParameter(valid_613332, JString, required = true,
                                 default = nil)
  if valid_613332 != nil:
    section.add "DomainName", valid_613332
  var valid_613333 = query.getOrDefault("Action")
  valid_613333 = validateParameter(valid_613333, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_613333 != nil:
    section.add "Action", valid_613333
  var valid_613334 = query.getOrDefault("Version")
  valid_613334 = validateParameter(valid_613334, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613334 != nil:
    section.add "Version", valid_613334
  var valid_613335 = query.getOrDefault("RankExpression.RankName")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "RankExpression.RankName", valid_613335
  var valid_613336 = query.getOrDefault("RankExpression.RankExpression")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "RankExpression.RankExpression", valid_613336
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613337 = header.getOrDefault("X-Amz-Signature")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Signature", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Content-Sha256", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Date")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Date", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Credential")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Credential", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Security-Token")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Security-Token", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Algorithm")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Algorithm", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-SignedHeaders", valid_613343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613344: Call_GetDefineRankExpression_613329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_613344.validator(path, query, header, formData, body)
  let scheme = call_613344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613344.url(scheme.get, call_613344.host, call_613344.base,
                         call_613344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613344, url, valid)

proc call*(call_613345: Call_GetDefineRankExpression_613329; DomainName: string;
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01";
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = ""): Recallable =
  ## getDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  var query_613346 = newJObject()
  add(query_613346, "DomainName", newJString(DomainName))
  add(query_613346, "Action", newJString(Action))
  add(query_613346, "Version", newJString(Version))
  add(query_613346, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_613346, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  result = call_613345.call(nil, query_613346, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_613329(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_613330, base: "/",
    url: url_GetDefineRankExpression_613331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_613382 = ref object of OpenApiRestCall_612658
proc url_PostDeleteDomain_613384(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_613383(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613385 = query.getOrDefault("Action")
  valid_613385 = validateParameter(valid_613385, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_613385 != nil:
    section.add "Action", valid_613385
  var valid_613386 = query.getOrDefault("Version")
  valid_613386 = validateParameter(valid_613386, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613386 != nil:
    section.add "Version", valid_613386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613387 = header.getOrDefault("X-Amz-Signature")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Signature", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Content-Sha256", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Date")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Date", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Credential")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Credential", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Security-Token")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Security-Token", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Algorithm")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Algorithm", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-SignedHeaders", valid_613393
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613394 = formData.getOrDefault("DomainName")
  valid_613394 = validateParameter(valid_613394, JString, required = true,
                                 default = nil)
  if valid_613394 != nil:
    section.add "DomainName", valid_613394
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613395: Call_PostDeleteDomain_613382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_613395.validator(path, query, header, formData, body)
  let scheme = call_613395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613395.url(scheme.get, call_613395.host, call_613395.base,
                         call_613395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613395, url, valid)

proc call*(call_613396: Call_PostDeleteDomain_613382; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613397 = newJObject()
  var formData_613398 = newJObject()
  add(formData_613398, "DomainName", newJString(DomainName))
  add(query_613397, "Action", newJString(Action))
  add(query_613397, "Version", newJString(Version))
  result = call_613396.call(nil, query_613397, nil, formData_613398, nil)

var postDeleteDomain* = Call_PostDeleteDomain_613382(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_613383,
    base: "/", url: url_PostDeleteDomain_613384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_613366 = ref object of OpenApiRestCall_612658
proc url_GetDeleteDomain_613368(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_613367(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613369 = query.getOrDefault("DomainName")
  valid_613369 = validateParameter(valid_613369, JString, required = true,
                                 default = nil)
  if valid_613369 != nil:
    section.add "DomainName", valid_613369
  var valid_613370 = query.getOrDefault("Action")
  valid_613370 = validateParameter(valid_613370, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_613370 != nil:
    section.add "Action", valid_613370
  var valid_613371 = query.getOrDefault("Version")
  valid_613371 = validateParameter(valid_613371, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613371 != nil:
    section.add "Version", valid_613371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613372 = header.getOrDefault("X-Amz-Signature")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Signature", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Content-Sha256", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Date")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Date", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Credential")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Credential", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Security-Token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Security-Token", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Algorithm")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Algorithm", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-SignedHeaders", valid_613378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613379: Call_GetDeleteDomain_613366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_613379.validator(path, query, header, formData, body)
  let scheme = call_613379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613379.url(scheme.get, call_613379.host, call_613379.base,
                         call_613379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613379, url, valid)

proc call*(call_613380: Call_GetDeleteDomain_613366; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613381 = newJObject()
  add(query_613381, "DomainName", newJString(DomainName))
  add(query_613381, "Action", newJString(Action))
  add(query_613381, "Version", newJString(Version))
  result = call_613380.call(nil, query_613381, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_613366(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_613367,
    base: "/", url: url_GetDeleteDomain_613368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_613416 = ref object of OpenApiRestCall_612658
proc url_PostDeleteIndexField_613418(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteIndexField_613417(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613419 = query.getOrDefault("Action")
  valid_613419 = validateParameter(valid_613419, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_613419 != nil:
    section.add "Action", valid_613419
  var valid_613420 = query.getOrDefault("Version")
  valid_613420 = validateParameter(valid_613420, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613420 != nil:
    section.add "Version", valid_613420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613421 = header.getOrDefault("X-Amz-Signature")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Signature", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Content-Sha256", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Date")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Date", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Credential")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Credential", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Security-Token")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Security-Token", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Algorithm")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Algorithm", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-SignedHeaders", valid_613427
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613428 = formData.getOrDefault("DomainName")
  valid_613428 = validateParameter(valid_613428, JString, required = true,
                                 default = nil)
  if valid_613428 != nil:
    section.add "DomainName", valid_613428
  var valid_613429 = formData.getOrDefault("IndexFieldName")
  valid_613429 = validateParameter(valid_613429, JString, required = true,
                                 default = nil)
  if valid_613429 != nil:
    section.add "IndexFieldName", valid_613429
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613430: Call_PostDeleteIndexField_613416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_613430.validator(path, query, header, formData, body)
  let scheme = call_613430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613430.url(scheme.get, call_613430.host, call_613430.base,
                         call_613430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613430, url, valid)

proc call*(call_613431: Call_PostDeleteIndexField_613416; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613432 = newJObject()
  var formData_613433 = newJObject()
  add(formData_613433, "DomainName", newJString(DomainName))
  add(formData_613433, "IndexFieldName", newJString(IndexFieldName))
  add(query_613432, "Action", newJString(Action))
  add(query_613432, "Version", newJString(Version))
  result = call_613431.call(nil, query_613432, nil, formData_613433, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_613416(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_613417, base: "/",
    url: url_PostDeleteIndexField_613418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_613399 = ref object of OpenApiRestCall_612658
proc url_GetDeleteIndexField_613401(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteIndexField_613400(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613402 = query.getOrDefault("DomainName")
  valid_613402 = validateParameter(valid_613402, JString, required = true,
                                 default = nil)
  if valid_613402 != nil:
    section.add "DomainName", valid_613402
  var valid_613403 = query.getOrDefault("Action")
  valid_613403 = validateParameter(valid_613403, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_613403 != nil:
    section.add "Action", valid_613403
  var valid_613404 = query.getOrDefault("IndexFieldName")
  valid_613404 = validateParameter(valid_613404, JString, required = true,
                                 default = nil)
  if valid_613404 != nil:
    section.add "IndexFieldName", valid_613404
  var valid_613405 = query.getOrDefault("Version")
  valid_613405 = validateParameter(valid_613405, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613405 != nil:
    section.add "Version", valid_613405
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613406 = header.getOrDefault("X-Amz-Signature")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Signature", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Content-Sha256", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Date")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Date", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Credential")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Credential", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Security-Token")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Security-Token", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Algorithm")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Algorithm", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-SignedHeaders", valid_613412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613413: Call_GetDeleteIndexField_613399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_613413.validator(path, query, header, formData, body)
  let scheme = call_613413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613413.url(scheme.get, call_613413.host, call_613413.base,
                         call_613413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613413, url, valid)

proc call*(call_613414: Call_GetDeleteIndexField_613399; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_613415 = newJObject()
  add(query_613415, "DomainName", newJString(DomainName))
  add(query_613415, "Action", newJString(Action))
  add(query_613415, "IndexFieldName", newJString(IndexFieldName))
  add(query_613415, "Version", newJString(Version))
  result = call_613414.call(nil, query_613415, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_613399(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_613400, base: "/",
    url: url_GetDeleteIndexField_613401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_613451 = ref object of OpenApiRestCall_612658
proc url_PostDeleteRankExpression_613453(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteRankExpression_613452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613454 = query.getOrDefault("Action")
  valid_613454 = validateParameter(valid_613454, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_613454 != nil:
    section.add "Action", valid_613454
  var valid_613455 = query.getOrDefault("Version")
  valid_613455 = validateParameter(valid_613455, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613455 != nil:
    section.add "Version", valid_613455
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613456 = header.getOrDefault("X-Amz-Signature")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Signature", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Content-Sha256", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Date")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Date", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Credential")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Credential", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Security-Token")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Security-Token", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Algorithm")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Algorithm", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-SignedHeaders", valid_613462
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RankName` field"
  var valid_613463 = formData.getOrDefault("RankName")
  valid_613463 = validateParameter(valid_613463, JString, required = true,
                                 default = nil)
  if valid_613463 != nil:
    section.add "RankName", valid_613463
  var valid_613464 = formData.getOrDefault("DomainName")
  valid_613464 = validateParameter(valid_613464, JString, required = true,
                                 default = nil)
  if valid_613464 != nil:
    section.add "DomainName", valid_613464
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613465: Call_PostDeleteRankExpression_613451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_613465.validator(path, query, header, formData, body)
  let scheme = call_613465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613465.url(scheme.get, call_613465.host, call_613465.base,
                         call_613465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613465, url, valid)

proc call*(call_613466: Call_PostDeleteRankExpression_613451; RankName: string;
          DomainName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613467 = newJObject()
  var formData_613468 = newJObject()
  add(formData_613468, "RankName", newJString(RankName))
  add(formData_613468, "DomainName", newJString(DomainName))
  add(query_613467, "Action", newJString(Action))
  add(query_613467, "Version", newJString(Version))
  result = call_613466.call(nil, query_613467, nil, formData_613468, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_613451(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_613452, base: "/",
    url: url_PostDeleteRankExpression_613453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_613434 = ref object of OpenApiRestCall_612658
proc url_GetDeleteRankExpression_613436(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteRankExpression_613435(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613437 = query.getOrDefault("DomainName")
  valid_613437 = validateParameter(valid_613437, JString, required = true,
                                 default = nil)
  if valid_613437 != nil:
    section.add "DomainName", valid_613437
  var valid_613438 = query.getOrDefault("RankName")
  valid_613438 = validateParameter(valid_613438, JString, required = true,
                                 default = nil)
  if valid_613438 != nil:
    section.add "RankName", valid_613438
  var valid_613439 = query.getOrDefault("Action")
  valid_613439 = validateParameter(valid_613439, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_613439 != nil:
    section.add "Action", valid_613439
  var valid_613440 = query.getOrDefault("Version")
  valid_613440 = validateParameter(valid_613440, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613440 != nil:
    section.add "Version", valid_613440
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613441 = header.getOrDefault("X-Amz-Signature")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Signature", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Content-Sha256", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-Date")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Date", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Credential")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Credential", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Security-Token")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Security-Token", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Algorithm")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Algorithm", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-SignedHeaders", valid_613447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613448: Call_GetDeleteRankExpression_613434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_613448.validator(path, query, header, formData, body)
  let scheme = call_613448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613448.url(scheme.get, call_613448.host, call_613448.base,
                         call_613448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613448, url, valid)

proc call*(call_613449: Call_GetDeleteRankExpression_613434; DomainName: string;
          RankName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613450 = newJObject()
  add(query_613450, "DomainName", newJString(DomainName))
  add(query_613450, "RankName", newJString(RankName))
  add(query_613450, "Action", newJString(Action))
  add(query_613450, "Version", newJString(Version))
  result = call_613449.call(nil, query_613450, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_613434(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_613435, base: "/",
    url: url_GetDeleteRankExpression_613436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_613485 = ref object of OpenApiRestCall_612658
proc url_PostDescribeAvailabilityOptions_613487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAvailabilityOptions_613486(path: JsonNode;
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
  var valid_613488 = query.getOrDefault("Action")
  valid_613488 = validateParameter(valid_613488, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_613488 != nil:
    section.add "Action", valid_613488
  var valid_613489 = query.getOrDefault("Version")
  valid_613489 = validateParameter(valid_613489, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613489 != nil:
    section.add "Version", valid_613489
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613490 = header.getOrDefault("X-Amz-Signature")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Signature", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Content-Sha256", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Date")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Date", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Credential")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Credential", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Security-Token")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Security-Token", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Algorithm")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Algorithm", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-SignedHeaders", valid_613496
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613497 = formData.getOrDefault("DomainName")
  valid_613497 = validateParameter(valid_613497, JString, required = true,
                                 default = nil)
  if valid_613497 != nil:
    section.add "DomainName", valid_613497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613498: Call_PostDescribeAvailabilityOptions_613485;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613498.validator(path, query, header, formData, body)
  let scheme = call_613498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613498.url(scheme.get, call_613498.host, call_613498.base,
                         call_613498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613498, url, valid)

proc call*(call_613499: Call_PostDescribeAvailabilityOptions_613485;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613500 = newJObject()
  var formData_613501 = newJObject()
  add(formData_613501, "DomainName", newJString(DomainName))
  add(query_613500, "Action", newJString(Action))
  add(query_613500, "Version", newJString(Version))
  result = call_613499.call(nil, query_613500, nil, formData_613501, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_613485(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_613486, base: "/",
    url: url_PostDescribeAvailabilityOptions_613487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_613469 = ref object of OpenApiRestCall_612658
proc url_GetDescribeAvailabilityOptions_613471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAvailabilityOptions_613470(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613472 = query.getOrDefault("DomainName")
  valid_613472 = validateParameter(valid_613472, JString, required = true,
                                 default = nil)
  if valid_613472 != nil:
    section.add "DomainName", valid_613472
  var valid_613473 = query.getOrDefault("Action")
  valid_613473 = validateParameter(valid_613473, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_613473 != nil:
    section.add "Action", valid_613473
  var valid_613474 = query.getOrDefault("Version")
  valid_613474 = validateParameter(valid_613474, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613474 != nil:
    section.add "Version", valid_613474
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613475 = header.getOrDefault("X-Amz-Signature")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Signature", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Content-Sha256", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Date")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Date", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Credential")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Credential", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Security-Token")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Security-Token", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Algorithm")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Algorithm", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-SignedHeaders", valid_613481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613482: Call_GetDescribeAvailabilityOptions_613469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613482.validator(path, query, header, formData, body)
  let scheme = call_613482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613482.url(scheme.get, call_613482.host, call_613482.base,
                         call_613482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613482, url, valid)

proc call*(call_613483: Call_GetDescribeAvailabilityOptions_613469;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613484 = newJObject()
  add(query_613484, "DomainName", newJString(DomainName))
  add(query_613484, "Action", newJString(Action))
  add(query_613484, "Version", newJString(Version))
  result = call_613483.call(nil, query_613484, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_613469(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_613470, base: "/",
    url: url_GetDescribeAvailabilityOptions_613471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_613518 = ref object of OpenApiRestCall_612658
proc url_PostDescribeDefaultSearchField_613520(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDefaultSearchField_613519(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613521 = query.getOrDefault("Action")
  valid_613521 = validateParameter(valid_613521, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_613521 != nil:
    section.add "Action", valid_613521
  var valid_613522 = query.getOrDefault("Version")
  valid_613522 = validateParameter(valid_613522, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613522 != nil:
    section.add "Version", valid_613522
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613523 = header.getOrDefault("X-Amz-Signature")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Signature", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Content-Sha256", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Date")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Date", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Credential")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Credential", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Security-Token")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Security-Token", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Algorithm")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Algorithm", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-SignedHeaders", valid_613529
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613530 = formData.getOrDefault("DomainName")
  valid_613530 = validateParameter(valid_613530, JString, required = true,
                                 default = nil)
  if valid_613530 != nil:
    section.add "DomainName", valid_613530
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613531: Call_PostDescribeDefaultSearchField_613518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_613531.validator(path, query, header, formData, body)
  let scheme = call_613531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613531.url(scheme.get, call_613531.host, call_613531.base,
                         call_613531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613531, url, valid)

proc call*(call_613532: Call_PostDescribeDefaultSearchField_613518;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613533 = newJObject()
  var formData_613534 = newJObject()
  add(formData_613534, "DomainName", newJString(DomainName))
  add(query_613533, "Action", newJString(Action))
  add(query_613533, "Version", newJString(Version))
  result = call_613532.call(nil, query_613533, nil, formData_613534, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_613518(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_613519, base: "/",
    url: url_PostDescribeDefaultSearchField_613520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_613502 = ref object of OpenApiRestCall_612658
proc url_GetDescribeDefaultSearchField_613504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDefaultSearchField_613503(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613505 = query.getOrDefault("DomainName")
  valid_613505 = validateParameter(valid_613505, JString, required = true,
                                 default = nil)
  if valid_613505 != nil:
    section.add "DomainName", valid_613505
  var valid_613506 = query.getOrDefault("Action")
  valid_613506 = validateParameter(valid_613506, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_613506 != nil:
    section.add "Action", valid_613506
  var valid_613507 = query.getOrDefault("Version")
  valid_613507 = validateParameter(valid_613507, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613507 != nil:
    section.add "Version", valid_613507
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613508 = header.getOrDefault("X-Amz-Signature")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Signature", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Content-Sha256", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Date")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Date", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Credential")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Credential", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Security-Token")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Security-Token", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Algorithm")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Algorithm", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-SignedHeaders", valid_613514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613515: Call_GetDescribeDefaultSearchField_613502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_613515.validator(path, query, header, formData, body)
  let scheme = call_613515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613515.url(scheme.get, call_613515.host, call_613515.base,
                         call_613515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613515, url, valid)

proc call*(call_613516: Call_GetDescribeDefaultSearchField_613502;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613517 = newJObject()
  add(query_613517, "DomainName", newJString(DomainName))
  add(query_613517, "Action", newJString(Action))
  add(query_613517, "Version", newJString(Version))
  result = call_613516.call(nil, query_613517, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_613502(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_613503, base: "/",
    url: url_GetDescribeDefaultSearchField_613504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_613551 = ref object of OpenApiRestCall_612658
proc url_PostDescribeDomains_613553(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomains_613552(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613554 = query.getOrDefault("Action")
  valid_613554 = validateParameter(valid_613554, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_613554 != nil:
    section.add "Action", valid_613554
  var valid_613555 = query.getOrDefault("Version")
  valid_613555 = validateParameter(valid_613555, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613555 != nil:
    section.add "Version", valid_613555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613556 = header.getOrDefault("X-Amz-Signature")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Signature", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Content-Sha256", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Date")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Date", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Credential")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Credential", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Security-Token")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Security-Token", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Algorithm")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Algorithm", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-SignedHeaders", valid_613562
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_613563 = formData.getOrDefault("DomainNames")
  valid_613563 = validateParameter(valid_613563, JArray, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "DomainNames", valid_613563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613564: Call_PostDescribeDomains_613551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_613564.validator(path, query, header, formData, body)
  let scheme = call_613564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613564.url(scheme.get, call_613564.host, call_613564.base,
                         call_613564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613564, url, valid)

proc call*(call_613565: Call_PostDescribeDomains_613551;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613566 = newJObject()
  var formData_613567 = newJObject()
  if DomainNames != nil:
    formData_613567.add "DomainNames", DomainNames
  add(query_613566, "Action", newJString(Action))
  add(query_613566, "Version", newJString(Version))
  result = call_613565.call(nil, query_613566, nil, formData_613567, nil)

var postDescribeDomains* = Call_PostDescribeDomains_613551(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_613552, base: "/",
    url: url_PostDescribeDomains_613553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_613535 = ref object of OpenApiRestCall_612658
proc url_GetDescribeDomains_613537(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomains_613536(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
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
  var valid_613538 = query.getOrDefault("DomainNames")
  valid_613538 = validateParameter(valid_613538, JArray, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "DomainNames", valid_613538
  var valid_613539 = query.getOrDefault("Action")
  valid_613539 = validateParameter(valid_613539, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_613539 != nil:
    section.add "Action", valid_613539
  var valid_613540 = query.getOrDefault("Version")
  valid_613540 = validateParameter(valid_613540, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613540 != nil:
    section.add "Version", valid_613540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613541 = header.getOrDefault("X-Amz-Signature")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Signature", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Content-Sha256", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Date")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Date", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Credential")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Credential", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Security-Token")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Security-Token", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Algorithm")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Algorithm", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-SignedHeaders", valid_613547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613548: Call_GetDescribeDomains_613535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_613548.validator(path, query, header, formData, body)
  let scheme = call_613548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613548.url(scheme.get, call_613548.host, call_613548.base,
                         call_613548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613548, url, valid)

proc call*(call_613549: Call_GetDescribeDomains_613535;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613550 = newJObject()
  if DomainNames != nil:
    query_613550.add "DomainNames", DomainNames
  add(query_613550, "Action", newJString(Action))
  add(query_613550, "Version", newJString(Version))
  result = call_613549.call(nil, query_613550, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_613535(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_613536, base: "/",
    url: url_GetDescribeDomains_613537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_613585 = ref object of OpenApiRestCall_612658
proc url_PostDescribeIndexFields_613587(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeIndexFields_613586(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613588 = query.getOrDefault("Action")
  valid_613588 = validateParameter(valid_613588, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_613588 != nil:
    section.add "Action", valid_613588
  var valid_613589 = query.getOrDefault("Version")
  valid_613589 = validateParameter(valid_613589, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613589 != nil:
    section.add "Version", valid_613589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613590 = header.getOrDefault("X-Amz-Signature")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Signature", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Content-Sha256", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Date")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Date", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Credential")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Credential", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Security-Token")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Security-Token", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Algorithm")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Algorithm", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-SignedHeaders", valid_613596
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_613597 = formData.getOrDefault("FieldNames")
  valid_613597 = validateParameter(valid_613597, JArray, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "FieldNames", valid_613597
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613598 = formData.getOrDefault("DomainName")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = nil)
  if valid_613598 != nil:
    section.add "DomainName", valid_613598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613599: Call_PostDescribeIndexFields_613585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_613599.validator(path, query, header, formData, body)
  let scheme = call_613599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613599.url(scheme.get, call_613599.host, call_613599.base,
                         call_613599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613599, url, valid)

proc call*(call_613600: Call_PostDescribeIndexFields_613585; DomainName: string;
          FieldNames: JsonNode = nil; Action: string = "DescribeIndexFields";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613601 = newJObject()
  var formData_613602 = newJObject()
  if FieldNames != nil:
    formData_613602.add "FieldNames", FieldNames
  add(formData_613602, "DomainName", newJString(DomainName))
  add(query_613601, "Action", newJString(Action))
  add(query_613601, "Version", newJString(Version))
  result = call_613600.call(nil, query_613601, nil, formData_613602, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_613585(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_613586, base: "/",
    url: url_PostDescribeIndexFields_613587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_613568 = ref object of OpenApiRestCall_612658
proc url_GetDescribeIndexFields_613570(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeIndexFields_613569(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613571 = query.getOrDefault("DomainName")
  valid_613571 = validateParameter(valid_613571, JString, required = true,
                                 default = nil)
  if valid_613571 != nil:
    section.add "DomainName", valid_613571
  var valid_613572 = query.getOrDefault("Action")
  valid_613572 = validateParameter(valid_613572, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_613572 != nil:
    section.add "Action", valid_613572
  var valid_613573 = query.getOrDefault("Version")
  valid_613573 = validateParameter(valid_613573, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613573 != nil:
    section.add "Version", valid_613573
  var valid_613574 = query.getOrDefault("FieldNames")
  valid_613574 = validateParameter(valid_613574, JArray, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "FieldNames", valid_613574
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613575 = header.getOrDefault("X-Amz-Signature")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Signature", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Content-Sha256", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Date")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Date", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Credential")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Credential", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Security-Token")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Security-Token", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Algorithm")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Algorithm", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-SignedHeaders", valid_613581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613582: Call_GetDescribeIndexFields_613568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_613582.validator(path, query, header, formData, body)
  let scheme = call_613582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613582.url(scheme.get, call_613582.host, call_613582.base,
                         call_613582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613582, url, valid)

proc call*(call_613583: Call_GetDescribeIndexFields_613568; DomainName: string;
          Action: string = "DescribeIndexFields"; Version: string = "2011-02-01";
          FieldNames: JsonNode = nil): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  var query_613584 = newJObject()
  add(query_613584, "DomainName", newJString(DomainName))
  add(query_613584, "Action", newJString(Action))
  add(query_613584, "Version", newJString(Version))
  if FieldNames != nil:
    query_613584.add "FieldNames", FieldNames
  result = call_613583.call(nil, query_613584, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_613568(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_613569, base: "/",
    url: url_GetDescribeIndexFields_613570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_613620 = ref object of OpenApiRestCall_612658
proc url_PostDescribeRankExpressions_613622(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeRankExpressions_613621(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613623 = query.getOrDefault("Action")
  valid_613623 = validateParameter(valid_613623, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_613623 != nil:
    section.add "Action", valid_613623
  var valid_613624 = query.getOrDefault("Version")
  valid_613624 = validateParameter(valid_613624, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613624 != nil:
    section.add "Version", valid_613624
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613625 = header.getOrDefault("X-Amz-Signature")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Signature", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Content-Sha256", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Date")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Date", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Credential")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Credential", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Security-Token")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Security-Token", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Algorithm")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Algorithm", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-SignedHeaders", valid_613631
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_613632 = formData.getOrDefault("RankNames")
  valid_613632 = validateParameter(valid_613632, JArray, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "RankNames", valid_613632
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613633 = formData.getOrDefault("DomainName")
  valid_613633 = validateParameter(valid_613633, JString, required = true,
                                 default = nil)
  if valid_613633 != nil:
    section.add "DomainName", valid_613633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613634: Call_PostDescribeRankExpressions_613620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_613634.validator(path, query, header, formData, body)
  let scheme = call_613634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613634.url(scheme.get, call_613634.host, call_613634.base,
                         call_613634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613634, url, valid)

proc call*(call_613635: Call_PostDescribeRankExpressions_613620;
          DomainName: string; RankNames: JsonNode = nil;
          Action: string = "DescribeRankExpressions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613636 = newJObject()
  var formData_613637 = newJObject()
  if RankNames != nil:
    formData_613637.add "RankNames", RankNames
  add(formData_613637, "DomainName", newJString(DomainName))
  add(query_613636, "Action", newJString(Action))
  add(query_613636, "Version", newJString(Version))
  result = call_613635.call(nil, query_613636, nil, formData_613637, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_613620(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_613621, base: "/",
    url: url_PostDescribeRankExpressions_613622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_613603 = ref object of OpenApiRestCall_612658
proc url_GetDescribeRankExpressions_613605(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeRankExpressions_613604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613606 = query.getOrDefault("DomainName")
  valid_613606 = validateParameter(valid_613606, JString, required = true,
                                 default = nil)
  if valid_613606 != nil:
    section.add "DomainName", valid_613606
  var valid_613607 = query.getOrDefault("RankNames")
  valid_613607 = validateParameter(valid_613607, JArray, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "RankNames", valid_613607
  var valid_613608 = query.getOrDefault("Action")
  valid_613608 = validateParameter(valid_613608, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_613608 != nil:
    section.add "Action", valid_613608
  var valid_613609 = query.getOrDefault("Version")
  valid_613609 = validateParameter(valid_613609, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613609 != nil:
    section.add "Version", valid_613609
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613610 = header.getOrDefault("X-Amz-Signature")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Signature", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Content-Sha256", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-Date")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Date", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-Credential")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Credential", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Security-Token")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Security-Token", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Algorithm")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Algorithm", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-SignedHeaders", valid_613616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613617: Call_GetDescribeRankExpressions_613603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_613617.validator(path, query, header, formData, body)
  let scheme = call_613617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613617.url(scheme.get, call_613617.host, call_613617.base,
                         call_613617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613617, url, valid)

proc call*(call_613618: Call_GetDescribeRankExpressions_613603; DomainName: string;
          RankNames: JsonNode = nil; Action: string = "DescribeRankExpressions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613619 = newJObject()
  add(query_613619, "DomainName", newJString(DomainName))
  if RankNames != nil:
    query_613619.add "RankNames", RankNames
  add(query_613619, "Action", newJString(Action))
  add(query_613619, "Version", newJString(Version))
  result = call_613618.call(nil, query_613619, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_613603(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_613604, base: "/",
    url: url_GetDescribeRankExpressions_613605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_613654 = ref object of OpenApiRestCall_612658
proc url_PostDescribeServiceAccessPolicies_613656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_613655(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613657 = query.getOrDefault("Action")
  valid_613657 = validateParameter(valid_613657, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_613657 != nil:
    section.add "Action", valid_613657
  var valid_613658 = query.getOrDefault("Version")
  valid_613658 = validateParameter(valid_613658, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613658 != nil:
    section.add "Version", valid_613658
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613659 = header.getOrDefault("X-Amz-Signature")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Signature", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Content-Sha256", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Date")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Date", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Credential")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Credential", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Security-Token")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Security-Token", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Algorithm")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Algorithm", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-SignedHeaders", valid_613665
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613666 = formData.getOrDefault("DomainName")
  valid_613666 = validateParameter(valid_613666, JString, required = true,
                                 default = nil)
  if valid_613666 != nil:
    section.add "DomainName", valid_613666
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613667: Call_PostDescribeServiceAccessPolicies_613654;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_613667.validator(path, query, header, formData, body)
  let scheme = call_613667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613667.url(scheme.get, call_613667.host, call_613667.base,
                         call_613667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613667, url, valid)

proc call*(call_613668: Call_PostDescribeServiceAccessPolicies_613654;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613669 = newJObject()
  var formData_613670 = newJObject()
  add(formData_613670, "DomainName", newJString(DomainName))
  add(query_613669, "Action", newJString(Action))
  add(query_613669, "Version", newJString(Version))
  result = call_613668.call(nil, query_613669, nil, formData_613670, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_613654(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_613655, base: "/",
    url: url_PostDescribeServiceAccessPolicies_613656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_613638 = ref object of OpenApiRestCall_612658
proc url_GetDescribeServiceAccessPolicies_613640(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_613639(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613641 = query.getOrDefault("DomainName")
  valid_613641 = validateParameter(valid_613641, JString, required = true,
                                 default = nil)
  if valid_613641 != nil:
    section.add "DomainName", valid_613641
  var valid_613642 = query.getOrDefault("Action")
  valid_613642 = validateParameter(valid_613642, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_613642 != nil:
    section.add "Action", valid_613642
  var valid_613643 = query.getOrDefault("Version")
  valid_613643 = validateParameter(valid_613643, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613643 != nil:
    section.add "Version", valid_613643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613644 = header.getOrDefault("X-Amz-Signature")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Signature", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Content-Sha256", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Date")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Date", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Credential")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Credential", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Security-Token")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Security-Token", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Algorithm")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Algorithm", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-SignedHeaders", valid_613650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613651: Call_GetDescribeServiceAccessPolicies_613638;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_613651.validator(path, query, header, formData, body)
  let scheme = call_613651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613651.url(scheme.get, call_613651.host, call_613651.base,
                         call_613651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613651, url, valid)

proc call*(call_613652: Call_GetDescribeServiceAccessPolicies_613638;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613653 = newJObject()
  add(query_613653, "DomainName", newJString(DomainName))
  add(query_613653, "Action", newJString(Action))
  add(query_613653, "Version", newJString(Version))
  result = call_613652.call(nil, query_613653, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_613638(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_613639, base: "/",
    url: url_GetDescribeServiceAccessPolicies_613640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_613687 = ref object of OpenApiRestCall_612658
proc url_PostDescribeStemmingOptions_613689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStemmingOptions_613688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613690 = query.getOrDefault("Action")
  valid_613690 = validateParameter(valid_613690, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_613690 != nil:
    section.add "Action", valid_613690
  var valid_613691 = query.getOrDefault("Version")
  valid_613691 = validateParameter(valid_613691, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613691 != nil:
    section.add "Version", valid_613691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613692 = header.getOrDefault("X-Amz-Signature")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Signature", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Content-Sha256", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Date")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Date", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Credential")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Credential", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Security-Token")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Security-Token", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Algorithm")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Algorithm", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-SignedHeaders", valid_613698
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613699 = formData.getOrDefault("DomainName")
  valid_613699 = validateParameter(valid_613699, JString, required = true,
                                 default = nil)
  if valid_613699 != nil:
    section.add "DomainName", valid_613699
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613700: Call_PostDescribeStemmingOptions_613687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_613700.validator(path, query, header, formData, body)
  let scheme = call_613700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613700.url(scheme.get, call_613700.host, call_613700.base,
                         call_613700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613700, url, valid)

proc call*(call_613701: Call_PostDescribeStemmingOptions_613687;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613702 = newJObject()
  var formData_613703 = newJObject()
  add(formData_613703, "DomainName", newJString(DomainName))
  add(query_613702, "Action", newJString(Action))
  add(query_613702, "Version", newJString(Version))
  result = call_613701.call(nil, query_613702, nil, formData_613703, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_613687(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_613688, base: "/",
    url: url_PostDescribeStemmingOptions_613689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_613671 = ref object of OpenApiRestCall_612658
proc url_GetDescribeStemmingOptions_613673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStemmingOptions_613672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613674 = query.getOrDefault("DomainName")
  valid_613674 = validateParameter(valid_613674, JString, required = true,
                                 default = nil)
  if valid_613674 != nil:
    section.add "DomainName", valid_613674
  var valid_613675 = query.getOrDefault("Action")
  valid_613675 = validateParameter(valid_613675, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_613675 != nil:
    section.add "Action", valid_613675
  var valid_613676 = query.getOrDefault("Version")
  valid_613676 = validateParameter(valid_613676, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613676 != nil:
    section.add "Version", valid_613676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613677 = header.getOrDefault("X-Amz-Signature")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Signature", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Content-Sha256", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Date")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Date", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Credential")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Credential", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Security-Token")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Security-Token", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Algorithm")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Algorithm", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-SignedHeaders", valid_613683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613684: Call_GetDescribeStemmingOptions_613671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_613684.validator(path, query, header, formData, body)
  let scheme = call_613684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613684.url(scheme.get, call_613684.host, call_613684.base,
                         call_613684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613684, url, valid)

proc call*(call_613685: Call_GetDescribeStemmingOptions_613671; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613686 = newJObject()
  add(query_613686, "DomainName", newJString(DomainName))
  add(query_613686, "Action", newJString(Action))
  add(query_613686, "Version", newJString(Version))
  result = call_613685.call(nil, query_613686, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_613671(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_613672, base: "/",
    url: url_GetDescribeStemmingOptions_613673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_613720 = ref object of OpenApiRestCall_612658
proc url_PostDescribeStopwordOptions_613722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStopwordOptions_613721(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613723 = query.getOrDefault("Action")
  valid_613723 = validateParameter(valid_613723, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_613723 != nil:
    section.add "Action", valid_613723
  var valid_613724 = query.getOrDefault("Version")
  valid_613724 = validateParameter(valid_613724, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613724 != nil:
    section.add "Version", valid_613724
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613725 = header.getOrDefault("X-Amz-Signature")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Signature", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Content-Sha256", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Date")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Date", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Credential")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Credential", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Security-Token")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Security-Token", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Algorithm")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Algorithm", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-SignedHeaders", valid_613731
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613732 = formData.getOrDefault("DomainName")
  valid_613732 = validateParameter(valid_613732, JString, required = true,
                                 default = nil)
  if valid_613732 != nil:
    section.add "DomainName", valid_613732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613733: Call_PostDescribeStopwordOptions_613720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_613733.validator(path, query, header, formData, body)
  let scheme = call_613733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613733.url(scheme.get, call_613733.host, call_613733.base,
                         call_613733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613733, url, valid)

proc call*(call_613734: Call_PostDescribeStopwordOptions_613720;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613735 = newJObject()
  var formData_613736 = newJObject()
  add(formData_613736, "DomainName", newJString(DomainName))
  add(query_613735, "Action", newJString(Action))
  add(query_613735, "Version", newJString(Version))
  result = call_613734.call(nil, query_613735, nil, formData_613736, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_613720(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_613721, base: "/",
    url: url_PostDescribeStopwordOptions_613722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_613704 = ref object of OpenApiRestCall_612658
proc url_GetDescribeStopwordOptions_613706(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStopwordOptions_613705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613707 = query.getOrDefault("DomainName")
  valid_613707 = validateParameter(valid_613707, JString, required = true,
                                 default = nil)
  if valid_613707 != nil:
    section.add "DomainName", valid_613707
  var valid_613708 = query.getOrDefault("Action")
  valid_613708 = validateParameter(valid_613708, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_613708 != nil:
    section.add "Action", valid_613708
  var valid_613709 = query.getOrDefault("Version")
  valid_613709 = validateParameter(valid_613709, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613709 != nil:
    section.add "Version", valid_613709
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613710 = header.getOrDefault("X-Amz-Signature")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Signature", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Content-Sha256", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Date")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Date", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Credential")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Credential", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Security-Token")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Security-Token", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Algorithm")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Algorithm", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-SignedHeaders", valid_613716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613717: Call_GetDescribeStopwordOptions_613704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_613717.validator(path, query, header, formData, body)
  let scheme = call_613717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613717.url(scheme.get, call_613717.host, call_613717.base,
                         call_613717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613717, url, valid)

proc call*(call_613718: Call_GetDescribeStopwordOptions_613704; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613719 = newJObject()
  add(query_613719, "DomainName", newJString(DomainName))
  add(query_613719, "Action", newJString(Action))
  add(query_613719, "Version", newJString(Version))
  result = call_613718.call(nil, query_613719, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_613704(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_613705, base: "/",
    url: url_GetDescribeStopwordOptions_613706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_613753 = ref object of OpenApiRestCall_612658
proc url_PostDescribeSynonymOptions_613755(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSynonymOptions_613754(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613756 = query.getOrDefault("Action")
  valid_613756 = validateParameter(valid_613756, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_613756 != nil:
    section.add "Action", valid_613756
  var valid_613757 = query.getOrDefault("Version")
  valid_613757 = validateParameter(valid_613757, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613757 != nil:
    section.add "Version", valid_613757
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613758 = header.getOrDefault("X-Amz-Signature")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Signature", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Content-Sha256", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Date")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Date", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Credential")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Credential", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-Security-Token")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Security-Token", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Algorithm")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Algorithm", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-SignedHeaders", valid_613764
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613765 = formData.getOrDefault("DomainName")
  valid_613765 = validateParameter(valid_613765, JString, required = true,
                                 default = nil)
  if valid_613765 != nil:
    section.add "DomainName", valid_613765
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613766: Call_PostDescribeSynonymOptions_613753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_613766.validator(path, query, header, formData, body)
  let scheme = call_613766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613766.url(scheme.get, call_613766.host, call_613766.base,
                         call_613766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613766, url, valid)

proc call*(call_613767: Call_PostDescribeSynonymOptions_613753; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613768 = newJObject()
  var formData_613769 = newJObject()
  add(formData_613769, "DomainName", newJString(DomainName))
  add(query_613768, "Action", newJString(Action))
  add(query_613768, "Version", newJString(Version))
  result = call_613767.call(nil, query_613768, nil, formData_613769, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_613753(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_613754, base: "/",
    url: url_PostDescribeSynonymOptions_613755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_613737 = ref object of OpenApiRestCall_612658
proc url_GetDescribeSynonymOptions_613739(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSynonymOptions_613738(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613740 = query.getOrDefault("DomainName")
  valid_613740 = validateParameter(valid_613740, JString, required = true,
                                 default = nil)
  if valid_613740 != nil:
    section.add "DomainName", valid_613740
  var valid_613741 = query.getOrDefault("Action")
  valid_613741 = validateParameter(valid_613741, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_613741 != nil:
    section.add "Action", valid_613741
  var valid_613742 = query.getOrDefault("Version")
  valid_613742 = validateParameter(valid_613742, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613742 != nil:
    section.add "Version", valid_613742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613743 = header.getOrDefault("X-Amz-Signature")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Signature", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Content-Sha256", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Date")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Date", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Credential")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Credential", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Security-Token")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Security-Token", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Algorithm")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Algorithm", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-SignedHeaders", valid_613749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613750: Call_GetDescribeSynonymOptions_613737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_613750.validator(path, query, header, formData, body)
  let scheme = call_613750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613750.url(scheme.get, call_613750.host, call_613750.base,
                         call_613750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613750, url, valid)

proc call*(call_613751: Call_GetDescribeSynonymOptions_613737; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613752 = newJObject()
  add(query_613752, "DomainName", newJString(DomainName))
  add(query_613752, "Action", newJString(Action))
  add(query_613752, "Version", newJString(Version))
  result = call_613751.call(nil, query_613752, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_613737(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_613738, base: "/",
    url: url_GetDescribeSynonymOptions_613739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_613786 = ref object of OpenApiRestCall_612658
proc url_PostIndexDocuments_613788(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostIndexDocuments_613787(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613789 = query.getOrDefault("Action")
  valid_613789 = validateParameter(valid_613789, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_613789 != nil:
    section.add "Action", valid_613789
  var valid_613790 = query.getOrDefault("Version")
  valid_613790 = validateParameter(valid_613790, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613790 != nil:
    section.add "Version", valid_613790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613791 = header.getOrDefault("X-Amz-Signature")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Signature", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Content-Sha256", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Date")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Date", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Credential")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Credential", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Security-Token")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Security-Token", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Algorithm")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Algorithm", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-SignedHeaders", valid_613797
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613798 = formData.getOrDefault("DomainName")
  valid_613798 = validateParameter(valid_613798, JString, required = true,
                                 default = nil)
  if valid_613798 != nil:
    section.add "DomainName", valid_613798
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613799: Call_PostIndexDocuments_613786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_613799.validator(path, query, header, formData, body)
  let scheme = call_613799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613799.url(scheme.get, call_613799.host, call_613799.base,
                         call_613799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613799, url, valid)

proc call*(call_613800: Call_PostIndexDocuments_613786; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613801 = newJObject()
  var formData_613802 = newJObject()
  add(formData_613802, "DomainName", newJString(DomainName))
  add(query_613801, "Action", newJString(Action))
  add(query_613801, "Version", newJString(Version))
  result = call_613800.call(nil, query_613801, nil, formData_613802, nil)

var postIndexDocuments* = Call_PostIndexDocuments_613786(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_613787, base: "/",
    url: url_PostIndexDocuments_613788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_613770 = ref object of OpenApiRestCall_612658
proc url_GetIndexDocuments_613772(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIndexDocuments_613771(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613773 = query.getOrDefault("DomainName")
  valid_613773 = validateParameter(valid_613773, JString, required = true,
                                 default = nil)
  if valid_613773 != nil:
    section.add "DomainName", valid_613773
  var valid_613774 = query.getOrDefault("Action")
  valid_613774 = validateParameter(valid_613774, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_613774 != nil:
    section.add "Action", valid_613774
  var valid_613775 = query.getOrDefault("Version")
  valid_613775 = validateParameter(valid_613775, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613775 != nil:
    section.add "Version", valid_613775
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613776 = header.getOrDefault("X-Amz-Signature")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Signature", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Content-Sha256", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Date")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Date", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Credential")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Credential", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Security-Token")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Security-Token", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Algorithm")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Algorithm", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-SignedHeaders", valid_613782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613783: Call_GetIndexDocuments_613770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_613783.validator(path, query, header, formData, body)
  let scheme = call_613783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613783.url(scheme.get, call_613783.host, call_613783.base,
                         call_613783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613783, url, valid)

proc call*(call_613784: Call_GetIndexDocuments_613770; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613785 = newJObject()
  add(query_613785, "DomainName", newJString(DomainName))
  add(query_613785, "Action", newJString(Action))
  add(query_613785, "Version", newJString(Version))
  result = call_613784.call(nil, query_613785, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_613770(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_613771,
    base: "/", url: url_GetIndexDocuments_613772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_613820 = ref object of OpenApiRestCall_612658
proc url_PostUpdateAvailabilityOptions_613822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateAvailabilityOptions_613821(path: JsonNode; query: JsonNode;
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
  var valid_613823 = query.getOrDefault("Action")
  valid_613823 = validateParameter(valid_613823, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_613823 != nil:
    section.add "Action", valid_613823
  var valid_613824 = query.getOrDefault("Version")
  valid_613824 = validateParameter(valid_613824, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613824 != nil:
    section.add "Version", valid_613824
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613825 = header.getOrDefault("X-Amz-Signature")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Signature", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Content-Sha256", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Date")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Date", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Credential")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Credential", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Security-Token")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Security-Token", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Algorithm")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Algorithm", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-SignedHeaders", valid_613831
  result.add "header", section
  ## parameters in `formData` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_613832 = formData.getOrDefault("MultiAZ")
  valid_613832 = validateParameter(valid_613832, JBool, required = true, default = nil)
  if valid_613832 != nil:
    section.add "MultiAZ", valid_613832
  var valid_613833 = formData.getOrDefault("DomainName")
  valid_613833 = validateParameter(valid_613833, JString, required = true,
                                 default = nil)
  if valid_613833 != nil:
    section.add "DomainName", valid_613833
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613834: Call_PostUpdateAvailabilityOptions_613820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613834.validator(path, query, header, formData, body)
  let scheme = call_613834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613834.url(scheme.get, call_613834.host, call_613834.base,
                         call_613834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613834, url, valid)

proc call*(call_613835: Call_PostUpdateAvailabilityOptions_613820; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613836 = newJObject()
  var formData_613837 = newJObject()
  add(formData_613837, "MultiAZ", newJBool(MultiAZ))
  add(formData_613837, "DomainName", newJString(DomainName))
  add(query_613836, "Action", newJString(Action))
  add(query_613836, "Version", newJString(Version))
  result = call_613835.call(nil, query_613836, nil, formData_613837, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_613820(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_613821, base: "/",
    url: url_PostUpdateAvailabilityOptions_613822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_613803 = ref object of OpenApiRestCall_612658
proc url_GetUpdateAvailabilityOptions_613805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateAvailabilityOptions_613804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613806 = query.getOrDefault("DomainName")
  valid_613806 = validateParameter(valid_613806, JString, required = true,
                                 default = nil)
  if valid_613806 != nil:
    section.add "DomainName", valid_613806
  var valid_613807 = query.getOrDefault("Action")
  valid_613807 = validateParameter(valid_613807, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_613807 != nil:
    section.add "Action", valid_613807
  var valid_613808 = query.getOrDefault("MultiAZ")
  valid_613808 = validateParameter(valid_613808, JBool, required = true, default = nil)
  if valid_613808 != nil:
    section.add "MultiAZ", valid_613808
  var valid_613809 = query.getOrDefault("Version")
  valid_613809 = validateParameter(valid_613809, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613809 != nil:
    section.add "Version", valid_613809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613810 = header.getOrDefault("X-Amz-Signature")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Signature", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Content-Sha256", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Date")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Date", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Credential")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Credential", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Security-Token")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Security-Token", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Algorithm")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Algorithm", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-SignedHeaders", valid_613816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613817: Call_GetUpdateAvailabilityOptions_613803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_613817.validator(path, query, header, formData, body)
  let scheme = call_613817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613817.url(scheme.get, call_613817.host, call_613817.base,
                         call_613817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613817, url, valid)

proc call*(call_613818: Call_GetUpdateAvailabilityOptions_613803;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: string (required)
  var query_613819 = newJObject()
  add(query_613819, "DomainName", newJString(DomainName))
  add(query_613819, "Action", newJString(Action))
  add(query_613819, "MultiAZ", newJBool(MultiAZ))
  add(query_613819, "Version", newJString(Version))
  result = call_613818.call(nil, query_613819, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_613803(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_613804, base: "/",
    url: url_GetUpdateAvailabilityOptions_613805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_613855 = ref object of OpenApiRestCall_612658
proc url_PostUpdateDefaultSearchField_613857(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateDefaultSearchField_613856(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613858 = query.getOrDefault("Action")
  valid_613858 = validateParameter(valid_613858, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_613858 != nil:
    section.add "Action", valid_613858
  var valid_613859 = query.getOrDefault("Version")
  valid_613859 = validateParameter(valid_613859, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613859 != nil:
    section.add "Version", valid_613859
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613860 = header.getOrDefault("X-Amz-Signature")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-Signature", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-Content-Sha256", valid_613861
  var valid_613862 = header.getOrDefault("X-Amz-Date")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Date", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Credential")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Credential", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Security-Token")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Security-Token", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Algorithm")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Algorithm", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-SignedHeaders", valid_613866
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613867 = formData.getOrDefault("DomainName")
  valid_613867 = validateParameter(valid_613867, JString, required = true,
                                 default = nil)
  if valid_613867 != nil:
    section.add "DomainName", valid_613867
  var valid_613868 = formData.getOrDefault("DefaultSearchField")
  valid_613868 = validateParameter(valid_613868, JString, required = true,
                                 default = nil)
  if valid_613868 != nil:
    section.add "DefaultSearchField", valid_613868
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613869: Call_PostUpdateDefaultSearchField_613855; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_613869.validator(path, query, header, formData, body)
  let scheme = call_613869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613869.url(scheme.get, call_613869.host, call_613869.base,
                         call_613869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613869, url, valid)

proc call*(call_613870: Call_PostUpdateDefaultSearchField_613855;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: string (required)
  var query_613871 = newJObject()
  var formData_613872 = newJObject()
  add(formData_613872, "DomainName", newJString(DomainName))
  add(query_613871, "Action", newJString(Action))
  add(formData_613872, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_613871, "Version", newJString(Version))
  result = call_613870.call(nil, query_613871, nil, formData_613872, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_613855(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_613856, base: "/",
    url: url_PostUpdateDefaultSearchField_613857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_613838 = ref object of OpenApiRestCall_612658
proc url_GetUpdateDefaultSearchField_613840(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateDefaultSearchField_613839(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613841 = query.getOrDefault("DomainName")
  valid_613841 = validateParameter(valid_613841, JString, required = true,
                                 default = nil)
  if valid_613841 != nil:
    section.add "DomainName", valid_613841
  var valid_613842 = query.getOrDefault("DefaultSearchField")
  valid_613842 = validateParameter(valid_613842, JString, required = true,
                                 default = nil)
  if valid_613842 != nil:
    section.add "DefaultSearchField", valid_613842
  var valid_613843 = query.getOrDefault("Action")
  valid_613843 = validateParameter(valid_613843, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_613843 != nil:
    section.add "Action", valid_613843
  var valid_613844 = query.getOrDefault("Version")
  valid_613844 = validateParameter(valid_613844, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613844 != nil:
    section.add "Version", valid_613844
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613845 = header.getOrDefault("X-Amz-Signature")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Signature", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Content-Sha256", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Date")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Date", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Credential")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Credential", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Security-Token")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Security-Token", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Algorithm")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Algorithm", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-SignedHeaders", valid_613851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613852: Call_GetUpdateDefaultSearchField_613838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_613852.validator(path, query, header, formData, body)
  let scheme = call_613852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613852.url(scheme.get, call_613852.host, call_613852.base,
                         call_613852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613852, url, valid)

proc call*(call_613853: Call_GetUpdateDefaultSearchField_613838;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613854 = newJObject()
  add(query_613854, "DomainName", newJString(DomainName))
  add(query_613854, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_613854, "Action", newJString(Action))
  add(query_613854, "Version", newJString(Version))
  result = call_613853.call(nil, query_613854, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_613838(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_613839, base: "/",
    url: url_GetUpdateDefaultSearchField_613840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_613890 = ref object of OpenApiRestCall_612658
proc url_PostUpdateServiceAccessPolicies_613892(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_613891(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613893 = query.getOrDefault("Action")
  valid_613893 = validateParameter(valid_613893, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_613893 != nil:
    section.add "Action", valid_613893
  var valid_613894 = query.getOrDefault("Version")
  valid_613894 = validateParameter(valid_613894, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613894 != nil:
    section.add "Version", valid_613894
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613895 = header.getOrDefault("X-Amz-Signature")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Signature", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Content-Sha256", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Date")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Date", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Credential")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Credential", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Security-Token")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Security-Token", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Algorithm")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Algorithm", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-SignedHeaders", valid_613901
  result.add "header", section
  ## parameters in `formData` object:
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AccessPolicies` field"
  var valid_613902 = formData.getOrDefault("AccessPolicies")
  valid_613902 = validateParameter(valid_613902, JString, required = true,
                                 default = nil)
  if valid_613902 != nil:
    section.add "AccessPolicies", valid_613902
  var valid_613903 = formData.getOrDefault("DomainName")
  valid_613903 = validateParameter(valid_613903, JString, required = true,
                                 default = nil)
  if valid_613903 != nil:
    section.add "DomainName", valid_613903
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613904: Call_PostUpdateServiceAccessPolicies_613890;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_613904.validator(path, query, header, formData, body)
  let scheme = call_613904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613904.url(scheme.get, call_613904.host, call_613904.base,
                         call_613904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613904, url, valid)

proc call*(call_613905: Call_PostUpdateServiceAccessPolicies_613890;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613906 = newJObject()
  var formData_613907 = newJObject()
  add(formData_613907, "AccessPolicies", newJString(AccessPolicies))
  add(formData_613907, "DomainName", newJString(DomainName))
  add(query_613906, "Action", newJString(Action))
  add(query_613906, "Version", newJString(Version))
  result = call_613905.call(nil, query_613906, nil, formData_613907, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_613890(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_613891, base: "/",
    url: url_PostUpdateServiceAccessPolicies_613892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_613873 = ref object of OpenApiRestCall_612658
proc url_GetUpdateServiceAccessPolicies_613875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_613874(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_613876 = query.getOrDefault("DomainName")
  valid_613876 = validateParameter(valid_613876, JString, required = true,
                                 default = nil)
  if valid_613876 != nil:
    section.add "DomainName", valid_613876
  var valid_613877 = query.getOrDefault("Action")
  valid_613877 = validateParameter(valid_613877, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_613877 != nil:
    section.add "Action", valid_613877
  var valid_613878 = query.getOrDefault("Version")
  valid_613878 = validateParameter(valid_613878, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613878 != nil:
    section.add "Version", valid_613878
  var valid_613879 = query.getOrDefault("AccessPolicies")
  valid_613879 = validateParameter(valid_613879, JString, required = true,
                                 default = nil)
  if valid_613879 != nil:
    section.add "AccessPolicies", valid_613879
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613880 = header.getOrDefault("X-Amz-Signature")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Signature", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Content-Sha256", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Date")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Date", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Credential")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Credential", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Security-Token")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Security-Token", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Algorithm")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Algorithm", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-SignedHeaders", valid_613886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613887: Call_GetUpdateServiceAccessPolicies_613873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_613887.validator(path, query, header, formData, body)
  let scheme = call_613887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613887.url(scheme.get, call_613887.host, call_613887.base,
                         call_613887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613887, url, valid)

proc call*(call_613888: Call_GetUpdateServiceAccessPolicies_613873;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  var query_613889 = newJObject()
  add(query_613889, "DomainName", newJString(DomainName))
  add(query_613889, "Action", newJString(Action))
  add(query_613889, "Version", newJString(Version))
  add(query_613889, "AccessPolicies", newJString(AccessPolicies))
  result = call_613888.call(nil, query_613889, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_613873(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_613874, base: "/",
    url: url_GetUpdateServiceAccessPolicies_613875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_613925 = ref object of OpenApiRestCall_612658
proc url_PostUpdateStemmingOptions_613927(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStemmingOptions_613926(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613928 = query.getOrDefault("Action")
  valid_613928 = validateParameter(valid_613928, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_613928 != nil:
    section.add "Action", valid_613928
  var valid_613929 = query.getOrDefault("Version")
  valid_613929 = validateParameter(valid_613929, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613929 != nil:
    section.add "Version", valid_613929
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613930 = header.getOrDefault("X-Amz-Signature")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Signature", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Content-Sha256", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Date")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Date", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Credential")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Credential", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Security-Token")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Security-Token", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-Algorithm")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Algorithm", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-SignedHeaders", valid_613936
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_613937 = formData.getOrDefault("DomainName")
  valid_613937 = validateParameter(valid_613937, JString, required = true,
                                 default = nil)
  if valid_613937 != nil:
    section.add "DomainName", valid_613937
  var valid_613938 = formData.getOrDefault("Stems")
  valid_613938 = validateParameter(valid_613938, JString, required = true,
                                 default = nil)
  if valid_613938 != nil:
    section.add "Stems", valid_613938
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613939: Call_PostUpdateStemmingOptions_613925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_613939.validator(path, query, header, formData, body)
  let scheme = call_613939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613939.url(scheme.get, call_613939.host, call_613939.base,
                         call_613939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613939, url, valid)

proc call*(call_613940: Call_PostUpdateStemmingOptions_613925; DomainName: string;
          Stems: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   Version: string (required)
  var query_613941 = newJObject()
  var formData_613942 = newJObject()
  add(formData_613942, "DomainName", newJString(DomainName))
  add(query_613941, "Action", newJString(Action))
  add(formData_613942, "Stems", newJString(Stems))
  add(query_613941, "Version", newJString(Version))
  result = call_613940.call(nil, query_613941, nil, formData_613942, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_613925(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_613926, base: "/",
    url: url_PostUpdateStemmingOptions_613927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_613908 = ref object of OpenApiRestCall_612658
proc url_GetUpdateStemmingOptions_613910(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateStemmingOptions_613909(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Stems` field"
  var valid_613911 = query.getOrDefault("Stems")
  valid_613911 = validateParameter(valid_613911, JString, required = true,
                                 default = nil)
  if valid_613911 != nil:
    section.add "Stems", valid_613911
  var valid_613912 = query.getOrDefault("DomainName")
  valid_613912 = validateParameter(valid_613912, JString, required = true,
                                 default = nil)
  if valid_613912 != nil:
    section.add "DomainName", valid_613912
  var valid_613913 = query.getOrDefault("Action")
  valid_613913 = validateParameter(valid_613913, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_613913 != nil:
    section.add "Action", valid_613913
  var valid_613914 = query.getOrDefault("Version")
  valid_613914 = validateParameter(valid_613914, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613914 != nil:
    section.add "Version", valid_613914
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613915 = header.getOrDefault("X-Amz-Signature")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Signature", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Content-Sha256", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Date")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Date", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Credential")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Credential", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Security-Token")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Security-Token", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-Algorithm")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-Algorithm", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-SignedHeaders", valid_613921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613922: Call_GetUpdateStemmingOptions_613908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_613922.validator(path, query, header, formData, body)
  let scheme = call_613922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613922.url(scheme.get, call_613922.host, call_613922.base,
                         call_613922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613922, url, valid)

proc call*(call_613923: Call_GetUpdateStemmingOptions_613908; Stems: string;
          DomainName: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613924 = newJObject()
  add(query_613924, "Stems", newJString(Stems))
  add(query_613924, "DomainName", newJString(DomainName))
  add(query_613924, "Action", newJString(Action))
  add(query_613924, "Version", newJString(Version))
  result = call_613923.call(nil, query_613924, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_613908(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_613909, base: "/",
    url: url_GetUpdateStemmingOptions_613910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_613960 = ref object of OpenApiRestCall_612658
proc url_PostUpdateStopwordOptions_613962(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStopwordOptions_613961(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613963 = query.getOrDefault("Action")
  valid_613963 = validateParameter(valid_613963, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_613963 != nil:
    section.add "Action", valid_613963
  var valid_613964 = query.getOrDefault("Version")
  valid_613964 = validateParameter(valid_613964, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613964 != nil:
    section.add "Version", valid_613964
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613965 = header.getOrDefault("X-Amz-Signature")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-Signature", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-Content-Sha256", valid_613966
  var valid_613967 = header.getOrDefault("X-Amz-Date")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Date", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Credential")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Credential", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Security-Token")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Security-Token", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Algorithm")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Algorithm", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-SignedHeaders", valid_613971
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_613972 = formData.getOrDefault("Stopwords")
  valid_613972 = validateParameter(valid_613972, JString, required = true,
                                 default = nil)
  if valid_613972 != nil:
    section.add "Stopwords", valid_613972
  var valid_613973 = formData.getOrDefault("DomainName")
  valid_613973 = validateParameter(valid_613973, JString, required = true,
                                 default = nil)
  if valid_613973 != nil:
    section.add "DomainName", valid_613973
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613974: Call_PostUpdateStopwordOptions_613960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_613974.validator(path, query, header, formData, body)
  let scheme = call_613974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613974.url(scheme.get, call_613974.host, call_613974.base,
                         call_613974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613974, url, valid)

proc call*(call_613975: Call_PostUpdateStopwordOptions_613960; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613976 = newJObject()
  var formData_613977 = newJObject()
  add(formData_613977, "Stopwords", newJString(Stopwords))
  add(formData_613977, "DomainName", newJString(DomainName))
  add(query_613976, "Action", newJString(Action))
  add(query_613976, "Version", newJString(Version))
  result = call_613975.call(nil, query_613976, nil, formData_613977, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_613960(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_613961, base: "/",
    url: url_PostUpdateStopwordOptions_613962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_613943 = ref object of OpenApiRestCall_612658
proc url_GetUpdateStopwordOptions_613945(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateStopwordOptions_613944(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Stopwords` field"
  var valid_613946 = query.getOrDefault("Stopwords")
  valid_613946 = validateParameter(valid_613946, JString, required = true,
                                 default = nil)
  if valid_613946 != nil:
    section.add "Stopwords", valid_613946
  var valid_613947 = query.getOrDefault("DomainName")
  valid_613947 = validateParameter(valid_613947, JString, required = true,
                                 default = nil)
  if valid_613947 != nil:
    section.add "DomainName", valid_613947
  var valid_613948 = query.getOrDefault("Action")
  valid_613948 = validateParameter(valid_613948, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_613948 != nil:
    section.add "Action", valid_613948
  var valid_613949 = query.getOrDefault("Version")
  valid_613949 = validateParameter(valid_613949, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613949 != nil:
    section.add "Version", valid_613949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613950 = header.getOrDefault("X-Amz-Signature")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-Signature", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-Content-Sha256", valid_613951
  var valid_613952 = header.getOrDefault("X-Amz-Date")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Date", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Credential")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Credential", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Security-Token")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Security-Token", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Algorithm")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Algorithm", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-SignedHeaders", valid_613956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613957: Call_GetUpdateStopwordOptions_613943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_613957.validator(path, query, header, formData, body)
  let scheme = call_613957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613957.url(scheme.get, call_613957.host, call_613957.base,
                         call_613957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613957, url, valid)

proc call*(call_613958: Call_GetUpdateStopwordOptions_613943; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613959 = newJObject()
  add(query_613959, "Stopwords", newJString(Stopwords))
  add(query_613959, "DomainName", newJString(DomainName))
  add(query_613959, "Action", newJString(Action))
  add(query_613959, "Version", newJString(Version))
  result = call_613958.call(nil, query_613959, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_613943(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_613944, base: "/",
    url: url_GetUpdateStopwordOptions_613945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_613995 = ref object of OpenApiRestCall_612658
proc url_PostUpdateSynonymOptions_613997(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateSynonymOptions_613996(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613998 = query.getOrDefault("Action")
  valid_613998 = validateParameter(valid_613998, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_613998 != nil:
    section.add "Action", valid_613998
  var valid_613999 = query.getOrDefault("Version")
  valid_613999 = validateParameter(valid_613999, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613999 != nil:
    section.add "Version", valid_613999
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614000 = header.getOrDefault("X-Amz-Signature")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-Signature", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-Content-Sha256", valid_614001
  var valid_614002 = header.getOrDefault("X-Amz-Date")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "X-Amz-Date", valid_614002
  var valid_614003 = header.getOrDefault("X-Amz-Credential")
  valid_614003 = validateParameter(valid_614003, JString, required = false,
                                 default = nil)
  if valid_614003 != nil:
    section.add "X-Amz-Credential", valid_614003
  var valid_614004 = header.getOrDefault("X-Amz-Security-Token")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "X-Amz-Security-Token", valid_614004
  var valid_614005 = header.getOrDefault("X-Amz-Algorithm")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Algorithm", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-SignedHeaders", valid_614006
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_614007 = formData.getOrDefault("DomainName")
  valid_614007 = validateParameter(valid_614007, JString, required = true,
                                 default = nil)
  if valid_614007 != nil:
    section.add "DomainName", valid_614007
  var valid_614008 = formData.getOrDefault("Synonyms")
  valid_614008 = validateParameter(valid_614008, JString, required = true,
                                 default = nil)
  if valid_614008 != nil:
    section.add "Synonyms", valid_614008
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614009: Call_PostUpdateSynonymOptions_613995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_614009.validator(path, query, header, formData, body)
  let scheme = call_614009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614009.url(scheme.get, call_614009.host, call_614009.base,
                         call_614009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614009, url, valid)

proc call*(call_614010: Call_PostUpdateSynonymOptions_613995; DomainName: string;
          Synonyms: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   Version: string (required)
  var query_614011 = newJObject()
  var formData_614012 = newJObject()
  add(formData_614012, "DomainName", newJString(DomainName))
  add(query_614011, "Action", newJString(Action))
  add(formData_614012, "Synonyms", newJString(Synonyms))
  add(query_614011, "Version", newJString(Version))
  result = call_614010.call(nil, query_614011, nil, formData_614012, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_613995(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_613996, base: "/",
    url: url_PostUpdateSynonymOptions_613997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_613978 = ref object of OpenApiRestCall_612658
proc url_GetUpdateSynonymOptions_613980(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateSynonymOptions_613979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Synonyms` field"
  var valid_613981 = query.getOrDefault("Synonyms")
  valid_613981 = validateParameter(valid_613981, JString, required = true,
                                 default = nil)
  if valid_613981 != nil:
    section.add "Synonyms", valid_613981
  var valid_613982 = query.getOrDefault("DomainName")
  valid_613982 = validateParameter(valid_613982, JString, required = true,
                                 default = nil)
  if valid_613982 != nil:
    section.add "DomainName", valid_613982
  var valid_613983 = query.getOrDefault("Action")
  valid_613983 = validateParameter(valid_613983, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_613983 != nil:
    section.add "Action", valid_613983
  var valid_613984 = query.getOrDefault("Version")
  valid_613984 = validateParameter(valid_613984, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_613984 != nil:
    section.add "Version", valid_613984
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613985 = header.getOrDefault("X-Amz-Signature")
  valid_613985 = validateParameter(valid_613985, JString, required = false,
                                 default = nil)
  if valid_613985 != nil:
    section.add "X-Amz-Signature", valid_613985
  var valid_613986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "X-Amz-Content-Sha256", valid_613986
  var valid_613987 = header.getOrDefault("X-Amz-Date")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "X-Amz-Date", valid_613987
  var valid_613988 = header.getOrDefault("X-Amz-Credential")
  valid_613988 = validateParameter(valid_613988, JString, required = false,
                                 default = nil)
  if valid_613988 != nil:
    section.add "X-Amz-Credential", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-Security-Token")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-Security-Token", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Algorithm")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Algorithm", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-SignedHeaders", valid_613991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613992: Call_GetUpdateSynonymOptions_613978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_613992.validator(path, query, header, formData, body)
  let scheme = call_613992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613992.url(scheme.get, call_613992.host, call_613992.base,
                         call_613992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613992, url, valid)

proc call*(call_613993: Call_GetUpdateSynonymOptions_613978; Synonyms: string;
          DomainName: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613994 = newJObject()
  add(query_613994, "Synonyms", newJString(Synonyms))
  add(query_613994, "DomainName", newJString(DomainName))
  add(query_613994, "Action", newJString(Action))
  add(query_613994, "Version", newJString(Version))
  result = call_613993.call(nil, query_613994, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_613978(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_613979, base: "/",
    url: url_GetUpdateSynonymOptions_613980, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
