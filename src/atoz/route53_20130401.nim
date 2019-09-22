
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Route 53
## version: 2013-04-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Route 53 is a highly available and scalable Domain Name System (DNS) web service.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/route53/
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "route53"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AssociateVPCWithHostedZone_602770 = ref object of OpenApiRestCall_602433
proc url_AssociateVPCWithHostedZone_602772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/associatevpc")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_AssociateVPCWithHostedZone_602771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : <p>The ID of the private hosted zone that you want to associate an Amazon VPC with.</p> <p>Note that you can't associate a VPC with a hosted zone that doesn't have an existing VPC association.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602898 = path.getOrDefault("Id")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = nil)
  if valid_602898 != nil:
    section.add "Id", valid_602898
  result.add "path", section
  section = newJObject()
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
  var valid_602899 = header.getOrDefault("X-Amz-Date")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-Date", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Security-Token")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Security-Token", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Content-Sha256", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Algorithm")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Algorithm", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Signature")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Signature", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-SignedHeaders", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Credential")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Credential", valid_602905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602929: Call_AssociateVPCWithHostedZone_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ## 
  let valid = call_602929.validator(path, query, header, formData, body)
  let scheme = call_602929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602929.url(scheme.get, call_602929.host, call_602929.base,
                         call_602929.route, valid.getOrDefault("path"))
  result = hook(call_602929, url, valid)

proc call*(call_603000: Call_AssociateVPCWithHostedZone_602770; Id: string;
          body: JsonNode): Recallable =
  ## associateVPCWithHostedZone
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ##   Id: string (required)
  ##     : <p>The ID of the private hosted zone that you want to associate an Amazon VPC with.</p> <p>Note that you can't associate a VPC with a hosted zone that doesn't have an existing VPC association.</p>
  ##   body: JObject (required)
  var path_603001 = newJObject()
  var body_603003 = newJObject()
  add(path_603001, "Id", newJString(Id))
  if body != nil:
    body_603003 = body
  result = call_603000.call(path_603001, nil, nil, nil, body_603003)

var associateVPCWithHostedZone* = Call_AssociateVPCWithHostedZone_602770(
    name: "associateVPCWithHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/associatevpc",
    validator: validate_AssociateVPCWithHostedZone_602771, base: "/",
    url: url_AssociateVPCWithHostedZone_602772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeResourceRecordSets_603042 = ref object of OpenApiRestCall_602433
proc url_ChangeResourceRecordSets_603044(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/rrset/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ChangeResourceRecordSets_603043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to change.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603045 = path.getOrDefault("Id")
  valid_603045 = validateParameter(valid_603045, JString, required = true,
                                 default = nil)
  if valid_603045 != nil:
    section.add "Id", valid_603045
  result.add "path", section
  section = newJObject()
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
  var valid_603046 = header.getOrDefault("X-Amz-Date")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Date", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Security-Token")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Security-Token", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Content-Sha256", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Algorithm")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Algorithm", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Signature")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Signature", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-SignedHeaders", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Credential")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Credential", valid_603052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603054: Call_ChangeResourceRecordSets_603042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_603054.validator(path, query, header, formData, body)
  let scheme = call_603054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603054.url(scheme.get, call_603054.host, call_603054.base,
                         call_603054.route, valid.getOrDefault("path"))
  result = hook(call_603054, url, valid)

proc call*(call_603055: Call_ChangeResourceRecordSets_603042; Id: string;
          body: JsonNode): Recallable =
  ## changeResourceRecordSets
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to change.
  ##   body: JObject (required)
  var path_603056 = newJObject()
  var body_603057 = newJObject()
  add(path_603056, "Id", newJString(Id))
  if body != nil:
    body_603057 = body
  result = call_603055.call(path_603056, nil, nil, nil, body_603057)

var changeResourceRecordSets* = Call_ChangeResourceRecordSets_603042(
    name: "changeResourceRecordSets", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset/",
    validator: validate_ChangeResourceRecordSets_603043, base: "/",
    url: url_ChangeResourceRecordSets_603044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeTagsForResource_603086 = ref object of OpenApiRestCall_602433
proc url_ChangeTagsForResource_603088(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ChangeTagsForResource_603087(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceType` field"
  var valid_603089 = path.getOrDefault("ResourceType")
  valid_603089 = validateParameter(valid_603089, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_603089 != nil:
    section.add "ResourceType", valid_603089
  var valid_603090 = path.getOrDefault("ResourceId")
  valid_603090 = validateParameter(valid_603090, JString, required = true,
                                 default = nil)
  if valid_603090 != nil:
    section.add "ResourceId", valid_603090
  result.add "path", section
  section = newJObject()
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
  var valid_603091 = header.getOrDefault("X-Amz-Date")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Date", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Security-Token")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Security-Token", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_ChangeTagsForResource_603086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_ChangeTagsForResource_603086; ResourceId: string;
          body: JsonNode; ResourceType: string = "healthcheck"): Recallable =
  ## changeTagsForResource
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  ##   body: JObject (required)
  var path_603101 = newJObject()
  var body_603102 = newJObject()
  add(path_603101, "ResourceType", newJString(ResourceType))
  add(path_603101, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_603102 = body
  result = call_603100.call(path_603101, nil, nil, nil, body_603102)

var changeTagsForResource* = Call_ChangeTagsForResource_603086(
    name: "changeTagsForResource", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ChangeTagsForResource_603087, base: "/",
    url: url_ChangeTagsForResource_603088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603058 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResource_603060(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListTagsForResource_603059(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceType` field"
  var valid_603074 = path.getOrDefault("ResourceType")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_603074 != nil:
    section.add "ResourceType", valid_603074
  var valid_603075 = path.getOrDefault("ResourceId")
  valid_603075 = validateParameter(valid_603075, JString, required = true,
                                 default = nil)
  if valid_603075 != nil:
    section.add "ResourceId", valid_603075
  result.add "path", section
  section = newJObject()
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
  var valid_603076 = header.getOrDefault("X-Amz-Date")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Date", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Security-Token")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Security-Token", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603083: Call_ListTagsForResource_603058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_603083.validator(path, query, header, formData, body)
  let scheme = call_603083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603083.url(scheme.get, call_603083.host, call_603083.base,
                         call_603083.route, valid.getOrDefault("path"))
  result = hook(call_603083, url, valid)

proc call*(call_603084: Call_ListTagsForResource_603058; ResourceId: string;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  var path_603085 = newJObject()
  add(path_603085, "ResourceType", newJString(ResourceType))
  add(path_603085, "ResourceId", newJString(ResourceId))
  result = call_603084.call(path_603085, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603058(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ListTagsForResource_603059, base: "/",
    url: url_ListTagsForResource_603060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHealthCheck_603120 = ref object of OpenApiRestCall_602433
proc url_CreateHealthCheck_603122(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateHealthCheck_603121(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603123 = header.getOrDefault("X-Amz-Date")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Date", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Security-Token")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Security-Token", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Content-Sha256", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Algorithm")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Algorithm", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Signature")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Signature", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-SignedHeaders", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Credential")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Credential", valid_603129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603131: Call_CreateHealthCheck_603120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ## 
  let valid = call_603131.validator(path, query, header, formData, body)
  let scheme = call_603131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603131.url(scheme.get, call_603131.host, call_603131.base,
                         call_603131.route, valid.getOrDefault("path"))
  result = hook(call_603131, url, valid)

proc call*(call_603132: Call_CreateHealthCheck_603120; body: JsonNode): Recallable =
  ## createHealthCheck
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603133 = newJObject()
  if body != nil:
    body_603133 = body
  result = call_603132.call(nil, nil, nil, nil, body_603133)

var createHealthCheck* = Call_CreateHealthCheck_603120(name: "createHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_CreateHealthCheck_603121,
    base: "/", url: url_CreateHealthCheck_603122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHealthChecks_603103 = ref object of OpenApiRestCall_602433
proc url_ListHealthChecks_603105(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListHealthChecks_603104(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_603106 = query.getOrDefault("marker")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "marker", valid_603106
  var valid_603107 = query.getOrDefault("maxitems")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "maxitems", valid_603107
  var valid_603108 = query.getOrDefault("Marker")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "Marker", valid_603108
  var valid_603109 = query.getOrDefault("MaxItems")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "MaxItems", valid_603109
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
  var valid_603110 = header.getOrDefault("X-Amz-Date")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Date", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Security-Token")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Security-Token", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Content-Sha256", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Algorithm")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Algorithm", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Signature")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Signature", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-SignedHeaders", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Credential")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Credential", valid_603116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603117: Call_ListHealthChecks_603103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  let valid = call_603117.validator(path, query, header, formData, body)
  let scheme = call_603117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603117.url(scheme.get, call_603117.host, call_603117.base,
                         call_603117.route, valid.getOrDefault("path"))
  result = hook(call_603117, url, valid)

proc call*(call_603118: Call_ListHealthChecks_603103; marker: string = "";
          maxitems: string = ""; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listHealthChecks
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  ##   maxitems: string
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  var query_603119 = newJObject()
  add(query_603119, "marker", newJString(marker))
  add(query_603119, "maxitems", newJString(maxitems))
  add(query_603119, "Marker", newJString(Marker))
  add(query_603119, "MaxItems", newJString(MaxItems))
  result = call_603118.call(nil, query_603119, nil, nil, nil)

var listHealthChecks* = Call_ListHealthChecks_603103(name: "listHealthChecks",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_ListHealthChecks_603104,
    base: "/", url: url_ListHealthChecks_603105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHostedZone_603152 = ref object of OpenApiRestCall_602433
proc url_CreateHostedZone_603154(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateHostedZone_603153(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603155 = header.getOrDefault("X-Amz-Date")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Date", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Security-Token")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Security-Token", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Content-Sha256", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Algorithm")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Algorithm", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Signature")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Signature", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-SignedHeaders", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Credential")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Credential", valid_603161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603163: Call_CreateHostedZone_603152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ## 
  let valid = call_603163.validator(path, query, header, formData, body)
  let scheme = call_603163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603163.url(scheme.get, call_603163.host, call_603163.base,
                         call_603163.route, valid.getOrDefault("path"))
  result = hook(call_603163, url, valid)

proc call*(call_603164: Call_CreateHostedZone_603152; body: JsonNode): Recallable =
  ## createHostedZone
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ##   body: JObject (required)
  var body_603165 = newJObject()
  if body != nil:
    body_603165 = body
  result = call_603164.call(nil, nil, nil, nil, body_603165)

var createHostedZone* = Call_CreateHostedZone_603152(name: "createHostedZone",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_CreateHostedZone_603153,
    base: "/", url: url_CreateHostedZone_603154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZones_603134 = ref object of OpenApiRestCall_602433
proc url_ListHostedZones_603136(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListHostedZones_603135(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   delegationsetid: JString
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_603137 = query.getOrDefault("delegationsetid")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "delegationsetid", valid_603137
  var valid_603138 = query.getOrDefault("marker")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "marker", valid_603138
  var valid_603139 = query.getOrDefault("maxitems")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "maxitems", valid_603139
  var valid_603140 = query.getOrDefault("Marker")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "Marker", valid_603140
  var valid_603141 = query.getOrDefault("MaxItems")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "MaxItems", valid_603141
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
  var valid_603142 = header.getOrDefault("X-Amz-Date")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Date", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Security-Token")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Security-Token", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Content-Sha256", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Algorithm")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Algorithm", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Signature")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Signature", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-SignedHeaders", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Credential")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Credential", valid_603148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603149: Call_ListHostedZones_603134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_603149.validator(path, query, header, formData, body)
  let scheme = call_603149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603149.url(scheme.get, call_603149.host, call_603149.base,
                         call_603149.route, valid.getOrDefault("path"))
  result = hook(call_603149, url, valid)

proc call*(call_603150: Call_ListHostedZones_603134; delegationsetid: string = "";
          marker: string = ""; maxitems: string = ""; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listHostedZones
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ##   delegationsetid: string
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  var query_603151 = newJObject()
  add(query_603151, "delegationsetid", newJString(delegationsetid))
  add(query_603151, "marker", newJString(marker))
  add(query_603151, "maxitems", newJString(maxitems))
  add(query_603151, "Marker", newJString(Marker))
  add(query_603151, "MaxItems", newJString(MaxItems))
  result = call_603150.call(nil, query_603151, nil, nil, nil)

var listHostedZones* = Call_ListHostedZones_603134(name: "listHostedZones",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_ListHostedZones_603135,
    base: "/", url: url_ListHostedZones_603136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueryLoggingConfig_603182 = ref object of OpenApiRestCall_602433
proc url_CreateQueryLoggingConfig_603184(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateQueryLoggingConfig_603183(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603185 = header.getOrDefault("X-Amz-Date")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Date", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Security-Token")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Security-Token", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Content-Sha256", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Algorithm")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Algorithm", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Signature")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Signature", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-SignedHeaders", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Credential")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Credential", valid_603191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603193: Call_CreateQueryLoggingConfig_603182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ## 
  let valid = call_603193.validator(path, query, header, formData, body)
  let scheme = call_603193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603193.url(scheme.get, call_603193.host, call_603193.base,
                         call_603193.route, valid.getOrDefault("path"))
  result = hook(call_603193, url, valid)

proc call*(call_603194: Call_CreateQueryLoggingConfig_603182; body: JsonNode): Recallable =
  ## createQueryLoggingConfig
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ##   body: JObject (required)
  var body_603195 = newJObject()
  if body != nil:
    body_603195 = body
  result = call_603194.call(nil, nil, nil, nil, body_603195)

var createQueryLoggingConfig* = Call_CreateQueryLoggingConfig_603182(
    name: "createQueryLoggingConfig", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_CreateQueryLoggingConfig_603183, base: "/",
    url: url_CreateQueryLoggingConfig_603184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueryLoggingConfigs_603166 = ref object of OpenApiRestCall_602433
proc url_ListQueryLoggingConfigs_603168(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListQueryLoggingConfigs_603167(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nexttoken: JString
  ##            : <p>(Optional) If the current AWS account has more than <code>MaxResults</code> query logging configurations, use <code>NextToken</code> to get the second and subsequent pages of results.</p> <p>For the first <code>ListQueryLoggingConfigs</code> request, omit this value.</p> <p>For the second and subsequent requests, get the value of <code>NextToken</code> from the previous response and specify that value for <code>NextToken</code> in the request.</p>
  ##   maxresults: JString
  ##             : <p>(Optional) The maximum number of query logging configurations that you want Amazon Route 53 to return in response to the current request. If the current AWS account has more than <code>MaxResults</code> configurations, use the value of <a 
  ## href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListQueryLoggingConfigs.html#API_ListQueryLoggingConfigs_RequestSyntax">NextToken</a> in the response to get the next page of results.</p> <p>If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 100 configurations.</p>
  ##   hostedzoneid: JString
  ##               : <p>(Optional) If you want to list the query logging configuration that is associated with a hosted zone, specify the ID in <code>HostedZoneId</code>. </p> <p>If you don't specify a hosted zone ID, <code>ListQueryLoggingConfigs</code> returns all of the configurations that are associated with the current AWS account.</p>
  section = newJObject()
  var valid_603169 = query.getOrDefault("nexttoken")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "nexttoken", valid_603169
  var valid_603170 = query.getOrDefault("maxresults")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "maxresults", valid_603170
  var valid_603171 = query.getOrDefault("hostedzoneid")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "hostedzoneid", valid_603171
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
  var valid_603172 = header.getOrDefault("X-Amz-Date")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Date", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Security-Token")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Security-Token", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Content-Sha256", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Algorithm")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Algorithm", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Signature")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Signature", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-SignedHeaders", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Credential")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Credential", valid_603178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603179: Call_ListQueryLoggingConfigs_603166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_603179.validator(path, query, header, formData, body)
  let scheme = call_603179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603179.url(scheme.get, call_603179.host, call_603179.base,
                         call_603179.route, valid.getOrDefault("path"))
  result = hook(call_603179, url, valid)

proc call*(call_603180: Call_ListQueryLoggingConfigs_603166;
          nexttoken: string = ""; maxresults: string = ""; hostedzoneid: string = ""): Recallable =
  ## listQueryLoggingConfigs
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   nexttoken: string
  ##            : <p>(Optional) If the current AWS account has more than <code>MaxResults</code> query logging configurations, use <code>NextToken</code> to get the second and subsequent pages of results.</p> <p>For the first <code>ListQueryLoggingConfigs</code> request, omit this value.</p> <p>For the second and subsequent requests, get the value of <code>NextToken</code> from the previous response and specify that value for <code>NextToken</code> in the request.</p>
  ##   maxresults: string
  ##             : <p>(Optional) The maximum number of query logging configurations that you want Amazon Route 53 to return in response to the current request. If the current AWS account has more than <code>MaxResults</code> configurations, use the value of <a 
  ## href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListQueryLoggingConfigs.html#API_ListQueryLoggingConfigs_RequestSyntax">NextToken</a> in the response to get the next page of results.</p> <p>If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 100 configurations.</p>
  ##   hostedzoneid: string
  ##               : <p>(Optional) If you want to list the query logging configuration that is associated with a hosted zone, specify the ID in <code>HostedZoneId</code>. </p> <p>If you don't specify a hosted zone ID, <code>ListQueryLoggingConfigs</code> returns all of the configurations that are associated with the current AWS account.</p>
  var query_603181 = newJObject()
  add(query_603181, "nexttoken", newJString(nexttoken))
  add(query_603181, "maxresults", newJString(maxresults))
  add(query_603181, "hostedzoneid", newJString(hostedzoneid))
  result = call_603180.call(nil, query_603181, nil, nil, nil)

var listQueryLoggingConfigs* = Call_ListQueryLoggingConfigs_603166(
    name: "listQueryLoggingConfigs", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_ListQueryLoggingConfigs_603167, base: "/",
    url: url_ListQueryLoggingConfigs_603168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReusableDelegationSet_603211 = ref object of OpenApiRestCall_602433
proc url_CreateReusableDelegationSet_603213(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateReusableDelegationSet_603212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603214 = header.getOrDefault("X-Amz-Date")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Date", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Security-Token")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Security-Token", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Content-Sha256", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Algorithm")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Algorithm", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Signature")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Signature", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-SignedHeaders", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Credential")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Credential", valid_603220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603222: Call_CreateReusableDelegationSet_603211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ## 
  let valid = call_603222.validator(path, query, header, formData, body)
  let scheme = call_603222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603222.url(scheme.get, call_603222.host, call_603222.base,
                         call_603222.route, valid.getOrDefault("path"))
  result = hook(call_603222, url, valid)

proc call*(call_603223: Call_CreateReusableDelegationSet_603211; body: JsonNode): Recallable =
  ## createReusableDelegationSet
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603224 = newJObject()
  if body != nil:
    body_603224 = body
  result = call_603223.call(nil, nil, nil, nil, body_603224)

var createReusableDelegationSet* = Call_CreateReusableDelegationSet_603211(
    name: "createReusableDelegationSet", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_CreateReusableDelegationSet_603212, base: "/",
    url: url_CreateReusableDelegationSet_603213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReusableDelegationSets_603196 = ref object of OpenApiRestCall_602433
proc url_ListReusableDelegationSets_603198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListReusableDelegationSets_603197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  ##   maxitems: JString
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  section = newJObject()
  var valid_603199 = query.getOrDefault("marker")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "marker", valid_603199
  var valid_603200 = query.getOrDefault("maxitems")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "maxitems", valid_603200
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
  var valid_603201 = header.getOrDefault("X-Amz-Date")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Date", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Security-Token")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Security-Token", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Content-Sha256", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Algorithm")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Algorithm", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Signature")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Signature", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-SignedHeaders", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Credential")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Credential", valid_603207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603208: Call_ListReusableDelegationSets_603196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  let valid = call_603208.validator(path, query, header, formData, body)
  let scheme = call_603208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603208.url(scheme.get, call_603208.host, call_603208.base,
                         call_603208.route, valid.getOrDefault("path"))
  result = hook(call_603208, url, valid)

proc call*(call_603209: Call_ListReusableDelegationSets_603196;
          marker: string = ""; maxitems: string = ""): Recallable =
  ## listReusableDelegationSets
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  ##   maxitems: string
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  var query_603210 = newJObject()
  add(query_603210, "marker", newJString(marker))
  add(query_603210, "maxitems", newJString(maxitems))
  result = call_603209.call(nil, query_603210, nil, nil, nil)

var listReusableDelegationSets* = Call_ListReusableDelegationSets_603196(
    name: "listReusableDelegationSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_ListReusableDelegationSets_603197, base: "/",
    url: url_ListReusableDelegationSets_603198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicy_603225 = ref object of OpenApiRestCall_602433
proc url_CreateTrafficPolicy_603227(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTrafficPolicy_603226(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603228 = header.getOrDefault("X-Amz-Date")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Date", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Security-Token")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Security-Token", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Content-Sha256", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Algorithm")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Algorithm", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Signature")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Signature", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-SignedHeaders", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Credential")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Credential", valid_603234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603236: Call_CreateTrafficPolicy_603225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ## 
  let valid = call_603236.validator(path, query, header, formData, body)
  let scheme = call_603236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603236.url(scheme.get, call_603236.host, call_603236.base,
                         call_603236.route, valid.getOrDefault("path"))
  result = hook(call_603236, url, valid)

proc call*(call_603237: Call_CreateTrafficPolicy_603225; body: JsonNode): Recallable =
  ## createTrafficPolicy
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ##   body: JObject (required)
  var body_603238 = newJObject()
  if body != nil:
    body_603238 = body
  result = call_603237.call(nil, nil, nil, nil, body_603238)

var createTrafficPolicy* = Call_CreateTrafficPolicy_603225(
    name: "createTrafficPolicy", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy",
    validator: validate_CreateTrafficPolicy_603226, base: "/",
    url: url_CreateTrafficPolicy_603227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyInstance_603239 = ref object of OpenApiRestCall_602433
proc url_CreateTrafficPolicyInstance_603241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTrafficPolicyInstance_603240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603242 = header.getOrDefault("X-Amz-Date")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Date", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Security-Token")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Security-Token", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Content-Sha256", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Algorithm")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Algorithm", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Signature")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Signature", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-SignedHeaders", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Credential")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Credential", valid_603248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603250: Call_CreateTrafficPolicyInstance_603239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ## 
  let valid = call_603250.validator(path, query, header, formData, body)
  let scheme = call_603250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603250.url(scheme.get, call_603250.host, call_603250.base,
                         call_603250.route, valid.getOrDefault("path"))
  result = hook(call_603250, url, valid)

proc call*(call_603251: Call_CreateTrafficPolicyInstance_603239; body: JsonNode): Recallable =
  ## createTrafficPolicyInstance
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ##   body: JObject (required)
  var body_603252 = newJObject()
  if body != nil:
    body_603252 = body
  result = call_603251.call(nil, nil, nil, nil, body_603252)

var createTrafficPolicyInstance* = Call_CreateTrafficPolicyInstance_603239(
    name: "createTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstance",
    validator: validate_CreateTrafficPolicyInstance_603240, base: "/",
    url: url_CreateTrafficPolicyInstance_603241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyVersion_603253 = ref object of OpenApiRestCall_602433
proc url_CreateTrafficPolicyVersion_603255(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateTrafficPolicyVersion_603254(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy for which you want to create a new version.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603256 = path.getOrDefault("Id")
  valid_603256 = validateParameter(valid_603256, JString, required = true,
                                 default = nil)
  if valid_603256 != nil:
    section.add "Id", valid_603256
  result.add "path", section
  section = newJObject()
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
  var valid_603257 = header.getOrDefault("X-Amz-Date")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Date", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Security-Token")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Security-Token", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Content-Sha256", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Algorithm")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Algorithm", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Signature")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Signature", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-SignedHeaders", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Credential")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Credential", valid_603263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603265: Call_CreateTrafficPolicyVersion_603253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ## 
  let valid = call_603265.validator(path, query, header, formData, body)
  let scheme = call_603265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603265.url(scheme.get, call_603265.host, call_603265.base,
                         call_603265.route, valid.getOrDefault("path"))
  result = hook(call_603265, url, valid)

proc call*(call_603266: Call_CreateTrafficPolicyVersion_603253; Id: string;
          body: JsonNode): Recallable =
  ## createTrafficPolicyVersion
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ##   Id: string (required)
  ##     : The ID of the traffic policy for which you want to create a new version.
  ##   body: JObject (required)
  var path_603267 = newJObject()
  var body_603268 = newJObject()
  add(path_603267, "Id", newJString(Id))
  if body != nil:
    body_603268 = body
  result = call_603266.call(path_603267, nil, nil, nil, body_603268)

var createTrafficPolicyVersion* = Call_CreateTrafficPolicyVersion_603253(
    name: "createTrafficPolicyVersion", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy/{Id}",
    validator: validate_CreateTrafficPolicyVersion_603254, base: "/",
    url: url_CreateTrafficPolicyVersion_603255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCAssociationAuthorization_603286 = ref object of OpenApiRestCall_602433
proc url_CreateVPCAssociationAuthorization_603288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/authorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_CreateVPCAssociationAuthorization_603287(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the private hosted zone that you want to authorize associating a VPC with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603289 = path.getOrDefault("Id")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = nil)
  if valid_603289 != nil:
    section.add "Id", valid_603289
  result.add "path", section
  section = newJObject()
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
  var valid_603290 = header.getOrDefault("X-Amz-Date")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Date", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Security-Token")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Security-Token", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Content-Sha256", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Algorithm")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Algorithm", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Signature")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Signature", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-SignedHeaders", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Credential")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Credential", valid_603296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603298: Call_CreateVPCAssociationAuthorization_603286;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ## 
  let valid = call_603298.validator(path, query, header, formData, body)
  let scheme = call_603298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603298.url(scheme.get, call_603298.host, call_603298.base,
                         call_603298.route, valid.getOrDefault("path"))
  result = hook(call_603298, url, valid)

proc call*(call_603299: Call_CreateVPCAssociationAuthorization_603286; Id: string;
          body: JsonNode): Recallable =
  ## createVPCAssociationAuthorization
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to authorize associating a VPC with.
  ##   body: JObject (required)
  var path_603300 = newJObject()
  var body_603301 = newJObject()
  add(path_603300, "Id", newJString(Id))
  if body != nil:
    body_603301 = body
  result = call_603299.call(path_603300, nil, nil, nil, body_603301)

var createVPCAssociationAuthorization* = Call_CreateVPCAssociationAuthorization_603286(
    name: "createVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_CreateVPCAssociationAuthorization_603287, base: "/",
    url: url_CreateVPCAssociationAuthorization_603288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCAssociationAuthorizations_603269 = ref object of OpenApiRestCall_602433
proc url_ListVPCAssociationAuthorizations_603271(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/authorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListVPCAssociationAuthorizations_603270(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone for which you want a list of VPCs that can be associated with the hosted zone.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603272 = path.getOrDefault("Id")
  valid_603272 = validateParameter(valid_603272, JString, required = true,
                                 default = nil)
  if valid_603272 != nil:
    section.add "Id", valid_603272
  result.add "path", section
  ## parameters in `query` object:
  ##   nexttoken: JString
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   maxresults: JString
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  section = newJObject()
  var valid_603273 = query.getOrDefault("nexttoken")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "nexttoken", valid_603273
  var valid_603274 = query.getOrDefault("maxresults")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "maxresults", valid_603274
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
  var valid_603275 = header.getOrDefault("X-Amz-Date")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Date", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Security-Token")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Security-Token", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Content-Sha256", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Algorithm")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Algorithm", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Signature")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Signature", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-SignedHeaders", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Credential")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Credential", valid_603281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603282: Call_ListVPCAssociationAuthorizations_603269;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ## 
  let valid = call_603282.validator(path, query, header, formData, body)
  let scheme = call_603282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603282.url(scheme.get, call_603282.host, call_603282.base,
                         call_603282.route, valid.getOrDefault("path"))
  result = hook(call_603282, url, valid)

proc call*(call_603283: Call_ListVPCAssociationAuthorizations_603269; Id: string;
          nexttoken: string = ""; maxresults: string = ""): Recallable =
  ## listVPCAssociationAuthorizations
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ##   nexttoken: string
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   Id: string (required)
  ##     : The ID of the hosted zone for which you want a list of VPCs that can be associated with the hosted zone.
  ##   maxresults: string
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  var path_603284 = newJObject()
  var query_603285 = newJObject()
  add(query_603285, "nexttoken", newJString(nexttoken))
  add(path_603284, "Id", newJString(Id))
  add(query_603285, "maxresults", newJString(maxresults))
  result = call_603283.call(path_603284, query_603285, nil, nil, nil)

var listVPCAssociationAuthorizations* = Call_ListVPCAssociationAuthorizations_603269(
    name: "listVPCAssociationAuthorizations", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_ListVPCAssociationAuthorizations_603270, base: "/",
    url: url_ListVPCAssociationAuthorizations_603271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHealthCheck_603316 = ref object of OpenApiRestCall_602433
proc url_UpdateHealthCheck_603318(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateHealthCheck_603317(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The ID for the health check for which you want detailed information. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603319 = path.getOrDefault("HealthCheckId")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = nil)
  if valid_603319 != nil:
    section.add "HealthCheckId", valid_603319
  result.add "path", section
  section = newJObject()
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
  var valid_603320 = header.getOrDefault("X-Amz-Date")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Date", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Security-Token")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Security-Token", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Content-Sha256", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Algorithm")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Algorithm", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Signature")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Signature", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-SignedHeaders", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Credential")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Credential", valid_603326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603328: Call_UpdateHealthCheck_603316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_603328.validator(path, query, header, formData, body)
  let scheme = call_603328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603328.url(scheme.get, call_603328.host, call_603328.base,
                         call_603328.route, valid.getOrDefault("path"))
  result = hook(call_603328, url, valid)

proc call*(call_603329: Call_UpdateHealthCheck_603316; HealthCheckId: string;
          body: JsonNode): Recallable =
  ## updateHealthCheck
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   HealthCheckId: string (required)
  ##                : The ID for the health check for which you want detailed information. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.
  ##   body: JObject (required)
  var path_603330 = newJObject()
  var body_603331 = newJObject()
  add(path_603330, "HealthCheckId", newJString(HealthCheckId))
  if body != nil:
    body_603331 = body
  result = call_603329.call(path_603330, nil, nil, nil, body_603331)

var updateHealthCheck* = Call_UpdateHealthCheck_603316(name: "updateHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_UpdateHealthCheck_603317, base: "/",
    url: url_UpdateHealthCheck_603318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheck_603302 = ref object of OpenApiRestCall_602433
proc url_GetHealthCheck_603304(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetHealthCheck_603303(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about a specified health check.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The identifier that Amazon Route 53 assigned to the health check when you created it. When you add or update a resource record set, you use this value to specify which health check to use. The value can be up to 64 characters long.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603305 = path.getOrDefault("HealthCheckId")
  valid_603305 = validateParameter(valid_603305, JString, required = true,
                                 default = nil)
  if valid_603305 != nil:
    section.add "HealthCheckId", valid_603305
  result.add "path", section
  section = newJObject()
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
  var valid_603306 = header.getOrDefault("X-Amz-Date")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Date", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Security-Token")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Security-Token", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Content-Sha256", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Algorithm")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Algorithm", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Signature")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Signature", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-SignedHeaders", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Credential")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Credential", valid_603312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603313: Call_GetHealthCheck_603302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified health check.
  ## 
  let valid = call_603313.validator(path, query, header, formData, body)
  let scheme = call_603313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603313.url(scheme.get, call_603313.host, call_603313.base,
                         call_603313.route, valid.getOrDefault("path"))
  result = hook(call_603313, url, valid)

proc call*(call_603314: Call_GetHealthCheck_603302; HealthCheckId: string): Recallable =
  ## getHealthCheck
  ## Gets information about a specified health check.
  ##   HealthCheckId: string (required)
  ##                : The identifier that Amazon Route 53 assigned to the health check when you created it. When you add or update a resource record set, you use this value to specify which health check to use. The value can be up to 64 characters long.
  var path_603315 = newJObject()
  add(path_603315, "HealthCheckId", newJString(HealthCheckId))
  result = call_603314.call(path_603315, nil, nil, nil, nil)

var getHealthCheck* = Call_GetHealthCheck_603302(name: "getHealthCheck",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_GetHealthCheck_603303, base: "/", url: url_GetHealthCheck_603304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHealthCheck_603332 = ref object of OpenApiRestCall_602433
proc url_DeleteHealthCheck_603334(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteHealthCheck_603333(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The ID of the health check that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603335 = path.getOrDefault("HealthCheckId")
  valid_603335 = validateParameter(valid_603335, JString, required = true,
                                 default = nil)
  if valid_603335 != nil:
    section.add "HealthCheckId", valid_603335
  result.add "path", section
  section = newJObject()
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
  var valid_603336 = header.getOrDefault("X-Amz-Date")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Date", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Security-Token")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Security-Token", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Content-Sha256", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Algorithm")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Algorithm", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Signature")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Signature", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-SignedHeaders", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Credential")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Credential", valid_603342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603343: Call_DeleteHealthCheck_603332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_603343.validator(path, query, header, formData, body)
  let scheme = call_603343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603343.url(scheme.get, call_603343.host, call_603343.base,
                         call_603343.route, valid.getOrDefault("path"))
  result = hook(call_603343, url, valid)

proc call*(call_603344: Call_DeleteHealthCheck_603332; HealthCheckId: string): Recallable =
  ## deleteHealthCheck
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ##   HealthCheckId: string (required)
  ##                : The ID of the health check that you want to delete.
  var path_603345 = newJObject()
  add(path_603345, "HealthCheckId", newJString(HealthCheckId))
  result = call_603344.call(path_603345, nil, nil, nil, nil)

var deleteHealthCheck* = Call_DeleteHealthCheck_603332(name: "deleteHealthCheck",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_DeleteHealthCheck_603333, base: "/",
    url: url_DeleteHealthCheck_603334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHostedZoneComment_603360 = ref object of OpenApiRestCall_602433
proc url_UpdateHostedZoneComment_603362(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateHostedZoneComment_603361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the comment for a specified hosted zone.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID for the hosted zone that you want to update the comment for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603363 = path.getOrDefault("Id")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = nil)
  if valid_603363 != nil:
    section.add "Id", valid_603363
  result.add "path", section
  section = newJObject()
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
  var valid_603364 = header.getOrDefault("X-Amz-Date")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Date", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Security-Token")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Security-Token", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Algorithm")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Algorithm", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Signature")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Signature", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-SignedHeaders", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Credential")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Credential", valid_603370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603372: Call_UpdateHostedZoneComment_603360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified hosted zone.
  ## 
  let valid = call_603372.validator(path, query, header, formData, body)
  let scheme = call_603372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603372.url(scheme.get, call_603372.host, call_603372.base,
                         call_603372.route, valid.getOrDefault("path"))
  result = hook(call_603372, url, valid)

proc call*(call_603373: Call_UpdateHostedZoneComment_603360; Id: string;
          body: JsonNode): Recallable =
  ## updateHostedZoneComment
  ## Updates the comment for a specified hosted zone.
  ##   Id: string (required)
  ##     : The ID for the hosted zone that you want to update the comment for.
  ##   body: JObject (required)
  var path_603374 = newJObject()
  var body_603375 = newJObject()
  add(path_603374, "Id", newJString(Id))
  if body != nil:
    body_603375 = body
  result = call_603373.call(path_603374, nil, nil, nil, body_603375)

var updateHostedZoneComment* = Call_UpdateHostedZoneComment_603360(
    name: "updateHostedZoneComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}",
    validator: validate_UpdateHostedZoneComment_603361, base: "/",
    url: url_UpdateHostedZoneComment_603362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZone_603346 = ref object of OpenApiRestCall_602433
proc url_GetHostedZone_603348(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetHostedZone_603347(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603349 = path.getOrDefault("Id")
  valid_603349 = validateParameter(valid_603349, JString, required = true,
                                 default = nil)
  if valid_603349 != nil:
    section.add "Id", valid_603349
  result.add "path", section
  section = newJObject()
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
  var valid_603350 = header.getOrDefault("X-Amz-Date")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Date", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Security-Token")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Security-Token", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Content-Sha256", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Algorithm")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Algorithm", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Signature")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Signature", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-SignedHeaders", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Credential")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Credential", valid_603356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603357: Call_GetHostedZone_603346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ## 
  let valid = call_603357.validator(path, query, header, formData, body)
  let scheme = call_603357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603357.url(scheme.get, call_603357.host, call_603357.base,
                         call_603357.route, valid.getOrDefault("path"))
  result = hook(call_603357, url, valid)

proc call*(call_603358: Call_GetHostedZone_603346; Id: string): Recallable =
  ## getHostedZone
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get information about.
  var path_603359 = newJObject()
  add(path_603359, "Id", newJString(Id))
  result = call_603358.call(path_603359, nil, nil, nil, nil)

var getHostedZone* = Call_GetHostedZone_603346(name: "getHostedZone",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_GetHostedZone_603347,
    base: "/", url: url_GetHostedZone_603348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHostedZone_603376 = ref object of OpenApiRestCall_602433
proc url_DeleteHostedZone_603378(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteHostedZone_603377(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603379 = path.getOrDefault("Id")
  valid_603379 = validateParameter(valid_603379, JString, required = true,
                                 default = nil)
  if valid_603379 != nil:
    section.add "Id", valid_603379
  result.add "path", section
  section = newJObject()
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
  var valid_603380 = header.getOrDefault("X-Amz-Date")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Date", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Security-Token")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Security-Token", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Content-Sha256", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Algorithm")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Algorithm", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Signature")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Signature", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-SignedHeaders", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Credential")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Credential", valid_603386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603387: Call_DeleteHostedZone_603376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ## 
  let valid = call_603387.validator(path, query, header, formData, body)
  let scheme = call_603387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603387.url(scheme.get, call_603387.host, call_603387.base,
                         call_603387.route, valid.getOrDefault("path"))
  result = hook(call_603387, url, valid)

proc call*(call_603388: Call_DeleteHostedZone_603376; Id: string): Recallable =
  ## deleteHostedZone
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the hosted zone you want to delete.
  var path_603389 = newJObject()
  add(path_603389, "Id", newJString(Id))
  result = call_603388.call(path_603389, nil, nil, nil, nil)

var deleteHostedZone* = Call_DeleteHostedZone_603376(name: "deleteHostedZone",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_DeleteHostedZone_603377,
    base: "/", url: url_DeleteHostedZone_603378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryLoggingConfig_603390 = ref object of OpenApiRestCall_602433
proc url_GetQueryLoggingConfig_603392(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/queryloggingconfig/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetQueryLoggingConfig_603391(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration for DNS query logging that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603393 = path.getOrDefault("Id")
  valid_603393 = validateParameter(valid_603393, JString, required = true,
                                 default = nil)
  if valid_603393 != nil:
    section.add "Id", valid_603393
  result.add "path", section
  section = newJObject()
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
  var valid_603394 = header.getOrDefault("X-Amz-Date")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Date", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Security-Token")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Security-Token", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Content-Sha256", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Algorithm")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Algorithm", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Signature")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Signature", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-SignedHeaders", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Credential")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Credential", valid_603400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603401: Call_GetQueryLoggingConfig_603390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ## 
  let valid = call_603401.validator(path, query, header, formData, body)
  let scheme = call_603401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603401.url(scheme.get, call_603401.host, call_603401.base,
                         call_603401.route, valid.getOrDefault("path"))
  result = hook(call_603401, url, valid)

proc call*(call_603402: Call_GetQueryLoggingConfig_603390; Id: string): Recallable =
  ## getQueryLoggingConfig
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration for DNS query logging that you want to get information about.
  var path_603403 = newJObject()
  add(path_603403, "Id", newJString(Id))
  result = call_603402.call(path_603403, nil, nil, nil, nil)

var getQueryLoggingConfig* = Call_GetQueryLoggingConfig_603390(
    name: "getQueryLoggingConfig", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_GetQueryLoggingConfig_603391, base: "/",
    url: url_GetQueryLoggingConfig_603392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueryLoggingConfig_603404 = ref object of OpenApiRestCall_602433
proc url_DeleteQueryLoggingConfig_603406(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/queryloggingconfig/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteQueryLoggingConfig_603405(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration that you want to delete. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603407 = path.getOrDefault("Id")
  valid_603407 = validateParameter(valid_603407, JString, required = true,
                                 default = nil)
  if valid_603407 != nil:
    section.add "Id", valid_603407
  result.add "path", section
  section = newJObject()
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
  var valid_603408 = header.getOrDefault("X-Amz-Date")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Date", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Security-Token")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Security-Token", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Content-Sha256", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Algorithm")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Algorithm", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Signature")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Signature", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-SignedHeaders", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Credential")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Credential", valid_603414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603415: Call_DeleteQueryLoggingConfig_603404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ## 
  let valid = call_603415.validator(path, query, header, formData, body)
  let scheme = call_603415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603415.url(scheme.get, call_603415.host, call_603415.base,
                         call_603415.route, valid.getOrDefault("path"))
  result = hook(call_603415, url, valid)

proc call*(call_603416: Call_DeleteQueryLoggingConfig_603404; Id: string): Recallable =
  ## deleteQueryLoggingConfig
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration that you want to delete. 
  var path_603417 = newJObject()
  add(path_603417, "Id", newJString(Id))
  result = call_603416.call(path_603417, nil, nil, nil, nil)

var deleteQueryLoggingConfig* = Call_DeleteQueryLoggingConfig_603404(
    name: "deleteQueryLoggingConfig", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_DeleteQueryLoggingConfig_603405, base: "/",
    url: url_DeleteQueryLoggingConfig_603406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSet_603418 = ref object of OpenApiRestCall_602433
proc url_GetReusableDelegationSet_603420(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/delegationset/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetReusableDelegationSet_603419(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the reusable delegation set that you want to get a list of name servers for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603421 = path.getOrDefault("Id")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = nil)
  if valid_603421 != nil:
    section.add "Id", valid_603421
  result.add "path", section
  section = newJObject()
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
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Security-Token")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Security-Token", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_GetReusableDelegationSet_603418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_GetReusableDelegationSet_603418; Id: string): Recallable =
  ## getReusableDelegationSet
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to get a list of name servers for.
  var path_603431 = newJObject()
  add(path_603431, "Id", newJString(Id))
  result = call_603430.call(path_603431, nil, nil, nil, nil)

var getReusableDelegationSet* = Call_GetReusableDelegationSet_603418(
    name: "getReusableDelegationSet", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_GetReusableDelegationSet_603419, base: "/",
    url: url_GetReusableDelegationSet_603420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReusableDelegationSet_603432 = ref object of OpenApiRestCall_602433
proc url_DeleteReusableDelegationSet_603434(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/delegationset/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteReusableDelegationSet_603433(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the reusable delegation set that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603435 = path.getOrDefault("Id")
  valid_603435 = validateParameter(valid_603435, JString, required = true,
                                 default = nil)
  if valid_603435 != nil:
    section.add "Id", valid_603435
  result.add "path", section
  section = newJObject()
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
  var valid_603436 = header.getOrDefault("X-Amz-Date")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Date", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Security-Token")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Security-Token", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Algorithm")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Algorithm", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603443: Call_DeleteReusableDelegationSet_603432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ## 
  let valid = call_603443.validator(path, query, header, formData, body)
  let scheme = call_603443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603443.url(scheme.get, call_603443.host, call_603443.base,
                         call_603443.route, valid.getOrDefault("path"))
  result = hook(call_603443, url, valid)

proc call*(call_603444: Call_DeleteReusableDelegationSet_603432; Id: string): Recallable =
  ## deleteReusableDelegationSet
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to delete.
  var path_603445 = newJObject()
  add(path_603445, "Id", newJString(Id))
  result = call_603444.call(path_603445, nil, nil, nil, nil)

var deleteReusableDelegationSet* = Call_DeleteReusableDelegationSet_603432(
    name: "deleteReusableDelegationSet", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_DeleteReusableDelegationSet_603433, base: "/",
    url: url_DeleteReusableDelegationSet_603434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyComment_603461 = ref object of OpenApiRestCall_602433
proc url_UpdateTrafficPolicyComment_603463(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateTrafficPolicyComment_603462(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the comment for a specified traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  ##   Version: JInt (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603464 = path.getOrDefault("Id")
  valid_603464 = validateParameter(valid_603464, JString, required = true,
                                 default = nil)
  if valid_603464 != nil:
    section.add "Id", valid_603464
  var valid_603465 = path.getOrDefault("Version")
  valid_603465 = validateParameter(valid_603465, JInt, required = true, default = nil)
  if valid_603465 != nil:
    section.add "Version", valid_603465
  result.add "path", section
  section = newJObject()
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
  var valid_603466 = header.getOrDefault("X-Amz-Date")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Date", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Security-Token")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Security-Token", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_UpdateTrafficPolicyComment_603461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified traffic policy version.
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_UpdateTrafficPolicyComment_603461; Id: string;
          Version: int; body: JsonNode): Recallable =
  ## updateTrafficPolicyComment
  ## Updates the comment for a specified traffic policy version.
  ##   Id: string (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  ##   Version: int (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  ##   body: JObject (required)
  var path_603476 = newJObject()
  var body_603477 = newJObject()
  add(path_603476, "Id", newJString(Id))
  add(path_603476, "Version", newJInt(Version))
  if body != nil:
    body_603477 = body
  result = call_603475.call(path_603476, nil, nil, nil, body_603477)

var updateTrafficPolicyComment* = Call_UpdateTrafficPolicyComment_603461(
    name: "updateTrafficPolicyComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_UpdateTrafficPolicyComment_603462, base: "/",
    url: url_UpdateTrafficPolicyComment_603463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicy_603446 = ref object of OpenApiRestCall_602433
proc url_GetTrafficPolicy_603448(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetTrafficPolicy_603447(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about a specific traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to get information about.
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603449 = path.getOrDefault("Id")
  valid_603449 = validateParameter(valid_603449, JString, required = true,
                                 default = nil)
  if valid_603449 != nil:
    section.add "Id", valid_603449
  var valid_603450 = path.getOrDefault("Version")
  valid_603450 = validateParameter(valid_603450, JInt, required = true, default = nil)
  if valid_603450 != nil:
    section.add "Version", valid_603450
  result.add "path", section
  section = newJObject()
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
  var valid_603451 = header.getOrDefault("X-Amz-Date")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Date", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Security-Token")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Security-Token", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Content-Sha256", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Algorithm")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Algorithm", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-SignedHeaders", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Credential")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Credential", valid_603457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603458: Call_GetTrafficPolicy_603446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific traffic policy version.
  ## 
  let valid = call_603458.validator(path, query, header, formData, body)
  let scheme = call_603458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603458.url(scheme.get, call_603458.host, call_603458.base,
                         call_603458.route, valid.getOrDefault("path"))
  result = hook(call_603458, url, valid)

proc call*(call_603459: Call_GetTrafficPolicy_603446; Id: string; Version: int): Recallable =
  ## getTrafficPolicy
  ## Gets information about a specific traffic policy version.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to get information about.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to get information about.
  var path_603460 = newJObject()
  add(path_603460, "Id", newJString(Id))
  add(path_603460, "Version", newJInt(Version))
  result = call_603459.call(path_603460, nil, nil, nil, nil)

var getTrafficPolicy* = Call_GetTrafficPolicy_603446(name: "getTrafficPolicy",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_GetTrafficPolicy_603447, base: "/",
    url: url_GetTrafficPolicy_603448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicy_603478 = ref object of OpenApiRestCall_602433
proc url_DeleteTrafficPolicy_603480(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteTrafficPolicy_603479(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a traffic policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to delete.
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603481 = path.getOrDefault("Id")
  valid_603481 = validateParameter(valid_603481, JString, required = true,
                                 default = nil)
  if valid_603481 != nil:
    section.add "Id", valid_603481
  var valid_603482 = path.getOrDefault("Version")
  valid_603482 = validateParameter(valid_603482, JInt, required = true, default = nil)
  if valid_603482 != nil:
    section.add "Version", valid_603482
  result.add "path", section
  section = newJObject()
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
  var valid_603483 = header.getOrDefault("X-Amz-Date")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Date", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Security-Token")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Security-Token", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Content-Sha256", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Algorithm")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Algorithm", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Signature")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Signature", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-SignedHeaders", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Credential")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Credential", valid_603489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603490: Call_DeleteTrafficPolicy_603478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a traffic policy.
  ## 
  let valid = call_603490.validator(path, query, header, formData, body)
  let scheme = call_603490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603490.url(scheme.get, call_603490.host, call_603490.base,
                         call_603490.route, valid.getOrDefault("path"))
  result = hook(call_603490, url, valid)

proc call*(call_603491: Call_DeleteTrafficPolicy_603478; Id: string; Version: int): Recallable =
  ## deleteTrafficPolicy
  ## Deletes a traffic policy.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to delete.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to delete.
  var path_603492 = newJObject()
  add(path_603492, "Id", newJString(Id))
  add(path_603492, "Version", newJInt(Version))
  result = call_603491.call(path_603492, nil, nil, nil, nil)

var deleteTrafficPolicy* = Call_DeleteTrafficPolicy_603478(
    name: "deleteTrafficPolicy", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_DeleteTrafficPolicy_603479, base: "/",
    url: url_DeleteTrafficPolicy_603480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyInstance_603507 = ref object of OpenApiRestCall_602433
proc url_UpdateTrafficPolicyInstance_603509(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateTrafficPolicyInstance_603508(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy instance that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603510 = path.getOrDefault("Id")
  valid_603510 = validateParameter(valid_603510, JString, required = true,
                                 default = nil)
  if valid_603510 != nil:
    section.add "Id", valid_603510
  result.add "path", section
  section = newJObject()
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
  var valid_603511 = header.getOrDefault("X-Amz-Date")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Date", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Security-Token")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Security-Token", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Content-Sha256", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Algorithm")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Algorithm", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Signature")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Signature", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-SignedHeaders", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Credential")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Credential", valid_603517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603519: Call_UpdateTrafficPolicyInstance_603507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ## 
  let valid = call_603519.validator(path, query, header, formData, body)
  let scheme = call_603519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603519.url(scheme.get, call_603519.host, call_603519.base,
                         call_603519.route, valid.getOrDefault("path"))
  result = hook(call_603519, url, valid)

proc call*(call_603520: Call_UpdateTrafficPolicyInstance_603507; Id: string;
          body: JsonNode): Recallable =
  ## updateTrafficPolicyInstance
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to update.
  ##   body: JObject (required)
  var path_603521 = newJObject()
  var body_603522 = newJObject()
  add(path_603521, "Id", newJString(Id))
  if body != nil:
    body_603522 = body
  result = call_603520.call(path_603521, nil, nil, nil, body_603522)

var updateTrafficPolicyInstance* = Call_UpdateTrafficPolicyInstance_603507(
    name: "updateTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_UpdateTrafficPolicyInstance_603508, base: "/",
    url: url_UpdateTrafficPolicyInstance_603509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstance_603493 = ref object of OpenApiRestCall_602433
proc url_GetTrafficPolicyInstance_603495(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetTrafficPolicyInstance_603494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy instance that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603496 = path.getOrDefault("Id")
  valid_603496 = validateParameter(valid_603496, JString, required = true,
                                 default = nil)
  if valid_603496 != nil:
    section.add "Id", valid_603496
  result.add "path", section
  section = newJObject()
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
  var valid_603497 = header.getOrDefault("X-Amz-Date")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Date", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Security-Token")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Security-Token", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Content-Sha256", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Algorithm")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Algorithm", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Signature")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Signature", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-SignedHeaders", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Credential")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Credential", valid_603503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_GetTrafficPolicyInstance_603493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"))
  result = hook(call_603504, url, valid)

proc call*(call_603505: Call_GetTrafficPolicyInstance_603493; Id: string): Recallable =
  ## getTrafficPolicyInstance
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to get information about.
  var path_603506 = newJObject()
  add(path_603506, "Id", newJString(Id))
  result = call_603505.call(path_603506, nil, nil, nil, nil)

var getTrafficPolicyInstance* = Call_GetTrafficPolicyInstance_603493(
    name: "getTrafficPolicyInstance", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_GetTrafficPolicyInstance_603494, base: "/",
    url: url_GetTrafficPolicyInstance_603495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicyInstance_603523 = ref object of OpenApiRestCall_602433
proc url_DeleteTrafficPolicyInstance_603525(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteTrafficPolicyInstance_603524(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : <p>The ID of the traffic policy instance that you want to delete. </p> <important> <p>When you delete a traffic policy instance, Amazon Route 53 also deletes all of the resource record sets that were created when you created the traffic policy instance.</p> </important>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603526 = path.getOrDefault("Id")
  valid_603526 = validateParameter(valid_603526, JString, required = true,
                                 default = nil)
  if valid_603526 != nil:
    section.add "Id", valid_603526
  result.add "path", section
  section = newJObject()
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
  var valid_603527 = header.getOrDefault("X-Amz-Date")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Date", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Security-Token")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Security-Token", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Content-Sha256", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Algorithm")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Algorithm", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Signature")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Signature", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-SignedHeaders", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Credential")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Credential", valid_603533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603534: Call_DeleteTrafficPolicyInstance_603523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_603534.validator(path, query, header, formData, body)
  let scheme = call_603534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603534.url(scheme.get, call_603534.host, call_603534.base,
                         call_603534.route, valid.getOrDefault("path"))
  result = hook(call_603534, url, valid)

proc call*(call_603535: Call_DeleteTrafficPolicyInstance_603523; Id: string): Recallable =
  ## deleteTrafficPolicyInstance
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : <p>The ID of the traffic policy instance that you want to delete. </p> <important> <p>When you delete a traffic policy instance, Amazon Route 53 also deletes all of the resource record sets that were created when you created the traffic policy instance.</p> </important>
  var path_603536 = newJObject()
  add(path_603536, "Id", newJString(Id))
  result = call_603535.call(path_603536, nil, nil, nil, nil)

var deleteTrafficPolicyInstance* = Call_DeleteTrafficPolicyInstance_603523(
    name: "deleteTrafficPolicyInstance", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_DeleteTrafficPolicyInstance_603524, base: "/",
    url: url_DeleteTrafficPolicyInstance_603525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCAssociationAuthorization_603537 = ref object of OpenApiRestCall_602433
proc url_DeleteVPCAssociationAuthorization_603539(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/deauthorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteVPCAssociationAuthorization_603538(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : When removing authorization to associate a VPC that was created by one AWS account with a hosted zone that was created with a different AWS account, the ID of the hosted zone.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603540 = path.getOrDefault("Id")
  valid_603540 = validateParameter(valid_603540, JString, required = true,
                                 default = nil)
  if valid_603540 != nil:
    section.add "Id", valid_603540
  result.add "path", section
  section = newJObject()
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
  var valid_603541 = header.getOrDefault("X-Amz-Date")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Date", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Security-Token")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Security-Token", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Content-Sha256", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603549: Call_DeleteVPCAssociationAuthorization_603537;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ## 
  let valid = call_603549.validator(path, query, header, formData, body)
  let scheme = call_603549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603549.url(scheme.get, call_603549.host, call_603549.base,
                         call_603549.route, valid.getOrDefault("path"))
  result = hook(call_603549, url, valid)

proc call*(call_603550: Call_DeleteVPCAssociationAuthorization_603537; Id: string;
          body: JsonNode): Recallable =
  ## deleteVPCAssociationAuthorization
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ##   Id: string (required)
  ##     : When removing authorization to associate a VPC that was created by one AWS account with a hosted zone that was created with a different AWS account, the ID of the hosted zone.
  ##   body: JObject (required)
  var path_603551 = newJObject()
  var body_603552 = newJObject()
  add(path_603551, "Id", newJString(Id))
  if body != nil:
    body_603552 = body
  result = call_603550.call(path_603551, nil, nil, nil, body_603552)

var deleteVPCAssociationAuthorization* = Call_DeleteVPCAssociationAuthorization_603537(
    name: "deleteVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/deauthorizevpcassociation",
    validator: validate_DeleteVPCAssociationAuthorization_603538, base: "/",
    url: url_DeleteVPCAssociationAuthorization_603539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateVPCFromHostedZone_603553 = ref object of OpenApiRestCall_602433
proc url_DisassociateVPCFromHostedZone_603555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/disassociatevpc")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DisassociateVPCFromHostedZone_603554(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the private hosted zone that you want to disassociate a VPC from.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603556 = path.getOrDefault("Id")
  valid_603556 = validateParameter(valid_603556, JString, required = true,
                                 default = nil)
  if valid_603556 != nil:
    section.add "Id", valid_603556
  result.add "path", section
  section = newJObject()
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
  var valid_603557 = header.getOrDefault("X-Amz-Date")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Date", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Security-Token")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Security-Token", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Content-Sha256", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Algorithm")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Algorithm", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Signature")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Signature", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-SignedHeaders", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Credential")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Credential", valid_603563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603565: Call_DisassociateVPCFromHostedZone_603553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ## 
  let valid = call_603565.validator(path, query, header, formData, body)
  let scheme = call_603565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603565.url(scheme.get, call_603565.host, call_603565.base,
                         call_603565.route, valid.getOrDefault("path"))
  result = hook(call_603565, url, valid)

proc call*(call_603566: Call_DisassociateVPCFromHostedZone_603553; Id: string;
          body: JsonNode): Recallable =
  ## disassociateVPCFromHostedZone
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to disassociate a VPC from.
  ##   body: JObject (required)
  var path_603567 = newJObject()
  var body_603568 = newJObject()
  add(path_603567, "Id", newJString(Id))
  if body != nil:
    body_603568 = body
  result = call_603566.call(path_603567, nil, nil, nil, body_603568)

var disassociateVPCFromHostedZone* = Call_DisassociateVPCFromHostedZone_603553(
    name: "disassociateVPCFromHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/disassociatevpc",
    validator: validate_DisassociateVPCFromHostedZone_603554, base: "/",
    url: url_DisassociateVPCFromHostedZone_603555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountLimit_603569 = ref object of OpenApiRestCall_602433
proc url_GetAccountLimit_603571(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/accountlimit/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetAccountLimit_603570(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_HEALTH_CHECKS_BY_OWNER</b>: The maximum number of health checks that you can create using the current account.</p> </li> <li> <p> <b>MAX_HOSTED_ZONES_BY_OWNER</b>: The maximum number of hosted zones that you can create using the current account.</p> </li> <li> <p> <b>MAX_REUSABLE_DELEGATION_SETS_BY_OWNER</b>: The maximum number of reusable delegation sets that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICIES_BY_OWNER</b>: The maximum number of traffic policies that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICY_INSTANCES_BY_OWNER</b>: The maximum number of traffic policy instances that you can create using the current account. (Traffic policy instances are referred to as traffic flow policy records in the Amazon Route 53 console.)</p> </li> </ul>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Type` field"
  var valid_603572 = path.getOrDefault("Type")
  valid_603572 = validateParameter(valid_603572, JString, required = true, default = newJString(
      "MAX_HEALTH_CHECKS_BY_OWNER"))
  if valid_603572 != nil:
    section.add "Type", valid_603572
  result.add "path", section
  section = newJObject()
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
  var valid_603573 = header.getOrDefault("X-Amz-Date")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Date", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Security-Token")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Security-Token", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Content-Sha256", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Algorithm")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Algorithm", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Signature")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Signature", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-SignedHeaders", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Credential")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Credential", valid_603579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603580: Call_GetAccountLimit_603569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ## 
  let valid = call_603580.validator(path, query, header, formData, body)
  let scheme = call_603580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603580.url(scheme.get, call_603580.host, call_603580.base,
                         call_603580.route, valid.getOrDefault("path"))
  result = hook(call_603580, url, valid)

proc call*(call_603581: Call_GetAccountLimit_603569;
          Type: string = "MAX_HEALTH_CHECKS_BY_OWNER"): Recallable =
  ## getAccountLimit
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_HEALTH_CHECKS_BY_OWNER</b>: The maximum number of health checks that you can create using the current account.</p> </li> <li> <p> <b>MAX_HOSTED_ZONES_BY_OWNER</b>: The maximum number of hosted zones that you can create using the current account.</p> </li> <li> <p> <b>MAX_REUSABLE_DELEGATION_SETS_BY_OWNER</b>: The maximum number of reusable delegation sets that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICIES_BY_OWNER</b>: The maximum number of traffic policies that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICY_INSTANCES_BY_OWNER</b>: The maximum number of traffic policy instances that you can create using the current account. (Traffic policy instances are referred to as traffic flow policy records in the Amazon Route 53 console.)</p> </li> </ul>
  var path_603582 = newJObject()
  add(path_603582, "Type", newJString(Type))
  result = call_603581.call(path_603582, nil, nil, nil, nil)

var getAccountLimit* = Call_GetAccountLimit_603569(name: "getAccountLimit",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/accountlimit/{Type}", validator: validate_GetAccountLimit_603570,
    base: "/", url: url_GetAccountLimit_603571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChange_603583 = ref object of OpenApiRestCall_602433
proc url_GetChange_603585(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/change/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetChange_603584(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the change batch request. The value that you specify here is the value that <code>ChangeResourceRecordSets</code> returned in the <code>Id</code> element when you submitted the request.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603586 = path.getOrDefault("Id")
  valid_603586 = validateParameter(valid_603586, JString, required = true,
                                 default = nil)
  if valid_603586 != nil:
    section.add "Id", valid_603586
  result.add "path", section
  section = newJObject()
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
  var valid_603587 = header.getOrDefault("X-Amz-Date")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Date", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Security-Token")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Security-Token", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Content-Sha256", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Algorithm")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Algorithm", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Signature")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Signature", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-SignedHeaders", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Credential")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Credential", valid_603593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603594: Call_GetChange_603583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ## 
  let valid = call_603594.validator(path, query, header, formData, body)
  let scheme = call_603594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603594.url(scheme.get, call_603594.host, call_603594.base,
                         call_603594.route, valid.getOrDefault("path"))
  result = hook(call_603594, url, valid)

proc call*(call_603595: Call_GetChange_603583; Id: string): Recallable =
  ## getChange
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the change batch request. The value that you specify here is the value that <code>ChangeResourceRecordSets</code> returned in the <code>Id</code> element when you submitted the request.
  var path_603596 = newJObject()
  add(path_603596, "Id", newJString(Id))
  result = call_603595.call(path_603596, nil, nil, nil, nil)

var getChange* = Call_GetChange_603583(name: "getChange", meth: HttpMethod.HttpGet,
                                    host: "route53.amazonaws.com",
                                    route: "/2013-04-01/change/{Id}",
                                    validator: validate_GetChange_603584,
                                    base: "/", url: url_GetChange_603585,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckerIpRanges_603597 = ref object of OpenApiRestCall_602433
proc url_GetCheckerIpRanges_603599(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCheckerIpRanges_603598(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603600 = header.getOrDefault("X-Amz-Date")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Date", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Security-Token")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Security-Token", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Content-Sha256", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Algorithm")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Algorithm", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Signature")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Signature", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-SignedHeaders", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Credential")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Credential", valid_603606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603607: Call_GetCheckerIpRanges_603597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_603607.validator(path, query, header, formData, body)
  let scheme = call_603607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603607.url(scheme.get, call_603607.host, call_603607.base,
                         call_603607.route, valid.getOrDefault("path"))
  result = hook(call_603607, url, valid)

proc call*(call_603608: Call_GetCheckerIpRanges_603597): Recallable =
  ## getCheckerIpRanges
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  result = call_603608.call(nil, nil, nil, nil, nil)

var getCheckerIpRanges* = Call_GetCheckerIpRanges_603597(
    name: "getCheckerIpRanges", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/checkeripranges",
    validator: validate_GetCheckerIpRanges_603598, base: "/",
    url: url_GetCheckerIpRanges_603599, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGeoLocation_603609 = ref object of OpenApiRestCall_602433
proc url_GetGeoLocation_603611(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGeoLocation_603610(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   continentcode: JString
  ##                : <p>Amazon Route 53 supports the following continent codes:</p> <ul> <li> <p> <b>AF</b>: Africa</p> </li> <li> <p> <b>AN</b>: Antarctica</p> </li> <li> <p> <b>AS</b>: Asia</p> </li> <li> <p> <b>EU</b>: Europe</p> </li> <li> <p> <b>OC</b>: Oceania</p> </li> <li> <p> <b>NA</b>: North America</p> </li> <li> <p> <b>SA</b>: South America</p> </li> </ul>
  ##   countrycode: JString
  ##              : Amazon Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.
  ##   subdivisioncode: JString
  ##                  : Amazon Route 53 uses the one- to three-letter subdivision codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>. Route 53 doesn't support subdivision codes for all countries. If you specify <code>subdivisioncode</code>, you must also specify <code>countrycode</code>. 
  section = newJObject()
  var valid_603612 = query.getOrDefault("continentcode")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "continentcode", valid_603612
  var valid_603613 = query.getOrDefault("countrycode")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "countrycode", valid_603613
  var valid_603614 = query.getOrDefault("subdivisioncode")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "subdivisioncode", valid_603614
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
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Security-Token")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Security-Token", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Content-Sha256", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Algorithm")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Algorithm", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Signature")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Signature", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-SignedHeaders", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Credential")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Credential", valid_603621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603622: Call_GetGeoLocation_603609; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ## 
  let valid = call_603622.validator(path, query, header, formData, body)
  let scheme = call_603622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603622.url(scheme.get, call_603622.host, call_603622.base,
                         call_603622.route, valid.getOrDefault("path"))
  result = hook(call_603622, url, valid)

proc call*(call_603623: Call_GetGeoLocation_603609; continentcode: string = "";
          countrycode: string = ""; subdivisioncode: string = ""): Recallable =
  ## getGeoLocation
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ##   continentcode: string
  ##                : <p>Amazon Route 53 supports the following continent codes:</p> <ul> <li> <p> <b>AF</b>: Africa</p> </li> <li> <p> <b>AN</b>: Antarctica</p> </li> <li> <p> <b>AS</b>: Asia</p> </li> <li> <p> <b>EU</b>: Europe</p> </li> <li> <p> <b>OC</b>: Oceania</p> </li> <li> <p> <b>NA</b>: North America</p> </li> <li> <p> <b>SA</b>: South America</p> </li> </ul>
  ##   countrycode: string
  ##              : Amazon Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.
  ##   subdivisioncode: string
  ##                  : Amazon Route 53 uses the one- to three-letter subdivision codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>. Route 53 doesn't support subdivision codes for all countries. If you specify <code>subdivisioncode</code>, you must also specify <code>countrycode</code>. 
  var query_603624 = newJObject()
  add(query_603624, "continentcode", newJString(continentcode))
  add(query_603624, "countrycode", newJString(countrycode))
  add(query_603624, "subdivisioncode", newJString(subdivisioncode))
  result = call_603623.call(nil, query_603624, nil, nil, nil)

var getGeoLocation* = Call_GetGeoLocation_603609(name: "getGeoLocation",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocation", validator: validate_GetGeoLocation_603610,
    base: "/", url: url_GetGeoLocation_603611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckCount_603625 = ref object of OpenApiRestCall_602433
proc url_GetHealthCheckCount_603627(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetHealthCheckCount_603626(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the number of health checks that are associated with the current AWS account.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603628 = header.getOrDefault("X-Amz-Date")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Date", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Security-Token")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Security-Token", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Content-Sha256", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Algorithm")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Algorithm", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Signature")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Signature", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-SignedHeaders", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Credential")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Credential", valid_603634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603635: Call_GetHealthCheckCount_603625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of health checks that are associated with the current AWS account.
  ## 
  let valid = call_603635.validator(path, query, header, formData, body)
  let scheme = call_603635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603635.url(scheme.get, call_603635.host, call_603635.base,
                         call_603635.route, valid.getOrDefault("path"))
  result = hook(call_603635, url, valid)

proc call*(call_603636: Call_GetHealthCheckCount_603625): Recallable =
  ## getHealthCheckCount
  ## Retrieves the number of health checks that are associated with the current AWS account.
  result = call_603636.call(nil, nil, nil, nil, nil)

var getHealthCheckCount* = Call_GetHealthCheckCount_603625(
    name: "getHealthCheckCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/healthcheckcount",
    validator: validate_GetHealthCheckCount_603626, base: "/",
    url: url_GetHealthCheckCount_603627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckLastFailureReason_603637 = ref object of OpenApiRestCall_602433
proc url_GetHealthCheckLastFailureReason_603639(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId"),
               (kind: ConstantSegment, value: "/lastfailurereason")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetHealthCheckLastFailureReason_603638(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the reason that a specified health check failed most recently.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : <p>The ID for the health check for which you want the last failure reason. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to get the last failure reason for a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckLastFailureReason</code> for a calculated health check.</p> </note>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603640 = path.getOrDefault("HealthCheckId")
  valid_603640 = validateParameter(valid_603640, JString, required = true,
                                 default = nil)
  if valid_603640 != nil:
    section.add "HealthCheckId", valid_603640
  result.add "path", section
  section = newJObject()
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
  var valid_603641 = header.getOrDefault("X-Amz-Date")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Date", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Security-Token")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Security-Token", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Content-Sha256", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Algorithm")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Algorithm", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Signature")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Signature", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-SignedHeaders", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Credential")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Credential", valid_603647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603648: Call_GetHealthCheckLastFailureReason_603637;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the reason that a specified health check failed most recently.
  ## 
  let valid = call_603648.validator(path, query, header, formData, body)
  let scheme = call_603648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603648.url(scheme.get, call_603648.host, call_603648.base,
                         call_603648.route, valid.getOrDefault("path"))
  result = hook(call_603648, url, valid)

proc call*(call_603649: Call_GetHealthCheckLastFailureReason_603637;
          HealthCheckId: string): Recallable =
  ## getHealthCheckLastFailureReason
  ## Gets the reason that a specified health check failed most recently.
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check for which you want the last failure reason. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to get the last failure reason for a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckLastFailureReason</code> for a calculated health check.</p> </note>
  var path_603650 = newJObject()
  add(path_603650, "HealthCheckId", newJString(HealthCheckId))
  result = call_603649.call(path_603650, nil, nil, nil, nil)

var getHealthCheckLastFailureReason* = Call_GetHealthCheckLastFailureReason_603637(
    name: "getHealthCheckLastFailureReason", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/lastfailurereason",
    validator: validate_GetHealthCheckLastFailureReason_603638, base: "/",
    url: url_GetHealthCheckLastFailureReason_603639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckStatus_603651 = ref object of OpenApiRestCall_602433
proc url_GetHealthCheckStatus_603653(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetHealthCheckStatus_603652(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets status of a specified health check. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : <p>The ID for the health check that you want the current status for. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to check the status of a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckStatus</code> to get the status of a calculated health check.</p> </note>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603654 = path.getOrDefault("HealthCheckId")
  valid_603654 = validateParameter(valid_603654, JString, required = true,
                                 default = nil)
  if valid_603654 != nil:
    section.add "HealthCheckId", valid_603654
  result.add "path", section
  section = newJObject()
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
  var valid_603655 = header.getOrDefault("X-Amz-Date")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Date", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Security-Token")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Security-Token", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Content-Sha256", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Algorithm")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Algorithm", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Signature")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Signature", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-SignedHeaders", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Credential")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Credential", valid_603661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603662: Call_GetHealthCheckStatus_603651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status of a specified health check. 
  ## 
  let valid = call_603662.validator(path, query, header, formData, body)
  let scheme = call_603662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603662.url(scheme.get, call_603662.host, call_603662.base,
                         call_603662.route, valid.getOrDefault("path"))
  result = hook(call_603662, url, valid)

proc call*(call_603663: Call_GetHealthCheckStatus_603651; HealthCheckId: string): Recallable =
  ## getHealthCheckStatus
  ## Gets status of a specified health check. 
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check that you want the current status for. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to check the status of a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckStatus</code> to get the status of a calculated health check.</p> </note>
  var path_603664 = newJObject()
  add(path_603664, "HealthCheckId", newJString(HealthCheckId))
  result = call_603663.call(path_603664, nil, nil, nil, nil)

var getHealthCheckStatus* = Call_GetHealthCheckStatus_603651(
    name: "getHealthCheckStatus", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/status",
    validator: validate_GetHealthCheckStatus_603652, base: "/",
    url: url_GetHealthCheckStatus_603653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneCount_603665 = ref object of OpenApiRestCall_602433
proc url_GetHostedZoneCount_603667(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetHostedZoneCount_603666(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603668 = header.getOrDefault("X-Amz-Date")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Date", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Security-Token")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Security-Token", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Content-Sha256", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Algorithm")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Algorithm", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Signature")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Signature", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-SignedHeaders", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Credential")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Credential", valid_603674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603675: Call_GetHostedZoneCount_603665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  ## 
  let valid = call_603675.validator(path, query, header, formData, body)
  let scheme = call_603675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603675.url(scheme.get, call_603675.host, call_603675.base,
                         call_603675.route, valid.getOrDefault("path"))
  result = hook(call_603675, url, valid)

proc call*(call_603676: Call_GetHostedZoneCount_603665): Recallable =
  ## getHostedZoneCount
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  result = call_603676.call(nil, nil, nil, nil, nil)

var getHostedZoneCount* = Call_GetHostedZoneCount_603665(
    name: "getHostedZoneCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonecount",
    validator: validate_GetHostedZoneCount_603666, base: "/",
    url: url_GetHostedZoneCount_603667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneLimit_603677 = ref object of OpenApiRestCall_602433
proc url_GetHostedZoneLimit_603679(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzonelimit/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetHostedZoneLimit_603678(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  ##   Type: JString (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603680 = path.getOrDefault("Id")
  valid_603680 = validateParameter(valid_603680, JString, required = true,
                                 default = nil)
  if valid_603680 != nil:
    section.add "Id", valid_603680
  var valid_603681 = path.getOrDefault("Type")
  valid_603681 = validateParameter(valid_603681, JString, required = true,
                                 default = newJString("MAX_RRSETS_BY_ZONE"))
  if valid_603681 != nil:
    section.add "Type", valid_603681
  result.add "path", section
  section = newJObject()
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
  var valid_603682 = header.getOrDefault("X-Amz-Date")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Date", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Security-Token")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Security-Token", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Content-Sha256", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Algorithm")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Algorithm", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Signature")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Signature", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-SignedHeaders", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Credential")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Credential", valid_603688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603689: Call_GetHostedZoneLimit_603677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_603689.validator(path, query, header, formData, body)
  let scheme = call_603689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603689.url(scheme.get, call_603689.host, call_603689.base,
                         call_603689.route, valid.getOrDefault("path"))
  result = hook(call_603689, url, valid)

proc call*(call_603690: Call_GetHostedZoneLimit_603677; Id: string;
          Type: string = "MAX_RRSETS_BY_ZONE"): Recallable =
  ## getHostedZoneLimit
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  var path_603691 = newJObject()
  add(path_603691, "Id", newJString(Id))
  add(path_603691, "Type", newJString(Type))
  result = call_603690.call(path_603691, nil, nil, nil, nil)

var getHostedZoneLimit* = Call_GetHostedZoneLimit_603677(
    name: "getHostedZoneLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzonelimit/{Id}/{Type}",
    validator: validate_GetHostedZoneLimit_603678, base: "/",
    url: url_GetHostedZoneLimit_603679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSetLimit_603692 = ref object of OpenApiRestCall_602433
proc url_GetReusableDelegationSetLimit_603694(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2013-04-01/reusabledelegationsetlimit/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetReusableDelegationSetLimit_603693(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  ##   Type: JString (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603695 = path.getOrDefault("Id")
  valid_603695 = validateParameter(valid_603695, JString, required = true,
                                 default = nil)
  if valid_603695 != nil:
    section.add "Id", valid_603695
  var valid_603696 = path.getOrDefault("Type")
  valid_603696 = validateParameter(valid_603696, JString, required = true, default = newJString(
      "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"))
  if valid_603696 != nil:
    section.add "Type", valid_603696
  result.add "path", section
  section = newJObject()
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
  var valid_603697 = header.getOrDefault("X-Amz-Date")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Date", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Security-Token")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Security-Token", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Content-Sha256", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Algorithm")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Algorithm", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Signature")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Signature", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-SignedHeaders", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-Credential")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Credential", valid_603703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603704: Call_GetReusableDelegationSetLimit_603692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_603704.validator(path, query, header, formData, body)
  let scheme = call_603704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603704.url(scheme.get, call_603704.host, call_603704.base,
                         call_603704.route, valid.getOrDefault("path"))
  result = hook(call_603704, url, valid)

proc call*(call_603705: Call_GetReusableDelegationSetLimit_603692; Id: string;
          Type: string = "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"): Recallable =
  ## getReusableDelegationSetLimit
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  ##   Type: string (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  var path_603706 = newJObject()
  add(path_603706, "Id", newJString(Id))
  add(path_603706, "Type", newJString(Type))
  result = call_603705.call(path_603706, nil, nil, nil, nil)

var getReusableDelegationSetLimit* = Call_GetReusableDelegationSetLimit_603692(
    name: "getReusableDelegationSetLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/reusabledelegationsetlimit/{Id}/{Type}",
    validator: validate_GetReusableDelegationSetLimit_603693, base: "/",
    url: url_GetReusableDelegationSetLimit_603694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstanceCount_603707 = ref object of OpenApiRestCall_602433
proc url_GetTrafficPolicyInstanceCount_603709(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTrafficPolicyInstanceCount_603708(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603710 = header.getOrDefault("X-Amz-Date")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Date", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-Security-Token")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Security-Token", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Content-Sha256", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Algorithm")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Algorithm", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-Signature")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-Signature", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-SignedHeaders", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Credential")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Credential", valid_603716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603717: Call_GetTrafficPolicyInstanceCount_603707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  ## 
  let valid = call_603717.validator(path, query, header, formData, body)
  let scheme = call_603717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603717.url(scheme.get, call_603717.host, call_603717.base,
                         call_603717.route, valid.getOrDefault("path"))
  result = hook(call_603717, url, valid)

proc call*(call_603718: Call_GetTrafficPolicyInstanceCount_603707): Recallable =
  ## getTrafficPolicyInstanceCount
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  result = call_603718.call(nil, nil, nil, nil, nil)

var getTrafficPolicyInstanceCount* = Call_GetTrafficPolicyInstanceCount_603707(
    name: "getTrafficPolicyInstanceCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstancecount",
    validator: validate_GetTrafficPolicyInstanceCount_603708, base: "/",
    url: url_GetTrafficPolicyInstanceCount_603709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGeoLocations_603719 = ref object of OpenApiRestCall_602433
proc url_ListGeoLocations_603721(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGeoLocations_603720(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   startcountrycode: JString
  ##                   : <p>The code for the country with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextCountryCode</code> from the previous response has a value, enter that value in <code>startcountrycode</code> to return the next page of results.</p> <p>Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.</p>
  ##   startsubdivisioncode: JString
  ##                       : <p>The code for the subdivision (for example, state or province) with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextSubdivisionCode</code> from the previous response has a value, enter that value in <code>startsubdivisioncode</code> to return the next page of results.</p> <p>To list subdivisions of a country, you must include both <code>startcountrycode</code> and <code>startsubdivisioncode</code>.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  ##   startcontinentcode: JString
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  section = newJObject()
  var valid_603722 = query.getOrDefault("startcountrycode")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "startcountrycode", valid_603722
  var valid_603723 = query.getOrDefault("startsubdivisioncode")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "startsubdivisioncode", valid_603723
  var valid_603724 = query.getOrDefault("maxitems")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "maxitems", valid_603724
  var valid_603725 = query.getOrDefault("startcontinentcode")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "startcontinentcode", valid_603725
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
  var valid_603726 = header.getOrDefault("X-Amz-Date")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Date", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Security-Token")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Security-Token", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Content-Sha256", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Algorithm")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Algorithm", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Signature")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Signature", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-SignedHeaders", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Credential")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Credential", valid_603732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603733: Call_ListGeoLocations_603719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ## 
  let valid = call_603733.validator(path, query, header, formData, body)
  let scheme = call_603733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603733.url(scheme.get, call_603733.host, call_603733.base,
                         call_603733.route, valid.getOrDefault("path"))
  result = hook(call_603733, url, valid)

proc call*(call_603734: Call_ListGeoLocations_603719;
          startcountrycode: string = ""; startsubdivisioncode: string = "";
          maxitems: string = ""; startcontinentcode: string = ""): Recallable =
  ## listGeoLocations
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ##   startcountrycode: string
  ##                   : <p>The code for the country with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextCountryCode</code> from the previous response has a value, enter that value in <code>startcountrycode</code> to return the next page of results.</p> <p>Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.</p>
  ##   startsubdivisioncode: string
  ##                       : <p>The code for the subdivision (for example, state or province) with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextSubdivisionCode</code> from the previous response has a value, enter that value in <code>startsubdivisioncode</code> to return the next page of results.</p> <p>To list subdivisions of a country, you must include both <code>startcountrycode</code> and <code>startsubdivisioncode</code>.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  ##   startcontinentcode: string
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  var query_603735 = newJObject()
  add(query_603735, "startcountrycode", newJString(startcountrycode))
  add(query_603735, "startsubdivisioncode", newJString(startsubdivisioncode))
  add(query_603735, "maxitems", newJString(maxitems))
  add(query_603735, "startcontinentcode", newJString(startcontinentcode))
  result = call_603734.call(nil, query_603735, nil, nil, nil)

var listGeoLocations* = Call_ListGeoLocations_603719(name: "listGeoLocations",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocations", validator: validate_ListGeoLocations_603720,
    base: "/", url: url_ListGeoLocations_603721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZonesByName_603736 = ref object of OpenApiRestCall_602433
proc url_ListHostedZonesByName_603738(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListHostedZonesByName_603737(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   dnsname: JString
  ##          : (Optional) For your first request to <code>ListHostedZonesByName</code>, include the <code>dnsname</code> parameter only if you want to specify the name of the first hosted zone in the response. If you don't include the <code>dnsname</code> parameter, Amazon Route 53 returns all of the hosted zones that were created by the current AWS account, in ASCII order. For subsequent requests, include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For <code>dnsname</code>, specify the value of <code>NextDNSName</code> from the previous response.
  ##   maxitems: JString
  ##           : The maximum number of hosted zones to be included in the response body for this request. If you have more than <code>maxitems</code> hosted zones, then the value of the <code>IsTruncated</code> element in the response is true, and the values of <code>NextDNSName</code> and <code>NextHostedZoneId</code> specify the first hosted zone in the next group of <code>maxitems</code> hosted zones. 
  ##   hostedzoneid: JString
  ##               : <p>(Optional) For your first request to <code>ListHostedZonesByName</code>, do not include the <code>hostedzoneid</code> parameter.</p> <p>If you have more hosted zones than the value of <code>maxitems</code>, <code>ListHostedZonesByName</code> returns only the first <code>maxitems</code> hosted zones. To get the next group of <code>maxitems</code> hosted zones, submit another request to <code>ListHostedZonesByName</code> and include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For the value of <code>hostedzoneid</code>, specify the value of the <code>NextHostedZoneId</code> element from the previous response.</p>
  section = newJObject()
  var valid_603739 = query.getOrDefault("dnsname")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "dnsname", valid_603739
  var valid_603740 = query.getOrDefault("maxitems")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "maxitems", valid_603740
  var valid_603741 = query.getOrDefault("hostedzoneid")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "hostedzoneid", valid_603741
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
  var valid_603742 = header.getOrDefault("X-Amz-Date")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Date", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Security-Token")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Security-Token", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Content-Sha256", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Algorithm")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Algorithm", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Signature")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Signature", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-SignedHeaders", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Credential")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Credential", valid_603748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603749: Call_ListHostedZonesByName_603736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ## 
  let valid = call_603749.validator(path, query, header, formData, body)
  let scheme = call_603749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603749.url(scheme.get, call_603749.host, call_603749.base,
                         call_603749.route, valid.getOrDefault("path"))
  result = hook(call_603749, url, valid)

proc call*(call_603750: Call_ListHostedZonesByName_603736; dnsname: string = "";
          maxitems: string = ""; hostedzoneid: string = ""): Recallable =
  ## listHostedZonesByName
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ##   dnsname: string
  ##          : (Optional) For your first request to <code>ListHostedZonesByName</code>, include the <code>dnsname</code> parameter only if you want to specify the name of the first hosted zone in the response. If you don't include the <code>dnsname</code> parameter, Amazon Route 53 returns all of the hosted zones that were created by the current AWS account, in ASCII order. For subsequent requests, include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For <code>dnsname</code>, specify the value of <code>NextDNSName</code> from the previous response.
  ##   maxitems: string
  ##           : The maximum number of hosted zones to be included in the response body for this request. If you have more than <code>maxitems</code> hosted zones, then the value of the <code>IsTruncated</code> element in the response is true, and the values of <code>NextDNSName</code> and <code>NextHostedZoneId</code> specify the first hosted zone in the next group of <code>maxitems</code> hosted zones. 
  ##   hostedzoneid: string
  ##               : <p>(Optional) For your first request to <code>ListHostedZonesByName</code>, do not include the <code>hostedzoneid</code> parameter.</p> <p>If you have more hosted zones than the value of <code>maxitems</code>, <code>ListHostedZonesByName</code> returns only the first <code>maxitems</code> hosted zones. To get the next group of <code>maxitems</code> hosted zones, submit another request to <code>ListHostedZonesByName</code> and include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For the value of <code>hostedzoneid</code>, specify the value of the <code>NextHostedZoneId</code> element from the previous response.</p>
  var query_603751 = newJObject()
  add(query_603751, "dnsname", newJString(dnsname))
  add(query_603751, "maxitems", newJString(maxitems))
  add(query_603751, "hostedzoneid", newJString(hostedzoneid))
  result = call_603750.call(nil, query_603751, nil, nil, nil)

var listHostedZonesByName* = Call_ListHostedZonesByName_603736(
    name: "listHostedZonesByName", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonesbyname",
    validator: validate_ListHostedZonesByName_603737, base: "/",
    url: url_ListHostedZonesByName_603738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceRecordSets_603752 = ref object of OpenApiRestCall_602433
proc url_ListResourceRecordSets_603754(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/rrset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListResourceRecordSets_603753(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to list.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603755 = path.getOrDefault("Id")
  valid_603755 = validateParameter(valid_603755, JString, required = true,
                                 default = nil)
  if valid_603755 != nil:
    section.add "Id", valid_603755
  result.add "path", section
  ## parameters in `query` object:
  ##   StartRecordIdentifier: JString
  ##                        : Pagination token
  ##   type: JString
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   identifier: JString
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  ##   StartRecordType: JString
  ##                  : Pagination token
  ##   maxitems: JString
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: JString
  ##                  : Pagination token
  ##   name: JString
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_603756 = query.getOrDefault("StartRecordIdentifier")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "StartRecordIdentifier", valid_603756
  var valid_603757 = query.getOrDefault("type")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = newJString("SOA"))
  if valid_603757 != nil:
    section.add "type", valid_603757
  var valid_603758 = query.getOrDefault("identifier")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "identifier", valid_603758
  var valid_603759 = query.getOrDefault("StartRecordType")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "StartRecordType", valid_603759
  var valid_603760 = query.getOrDefault("maxitems")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "maxitems", valid_603760
  var valid_603761 = query.getOrDefault("StartRecordName")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "StartRecordName", valid_603761
  var valid_603762 = query.getOrDefault("name")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "name", valid_603762
  var valid_603763 = query.getOrDefault("MaxItems")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "MaxItems", valid_603763
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
  var valid_603764 = header.getOrDefault("X-Amz-Date")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Date", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Security-Token")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Security-Token", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Content-Sha256", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Algorithm")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Algorithm", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Signature")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Signature", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-SignedHeaders", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Credential")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Credential", valid_603770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603771: Call_ListResourceRecordSets_603752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ## 
  let valid = call_603771.validator(path, query, header, formData, body)
  let scheme = call_603771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603771.url(scheme.get, call_603771.host, call_603771.base,
                         call_603771.route, valid.getOrDefault("path"))
  result = hook(call_603771, url, valid)

proc call*(call_603772: Call_ListResourceRecordSets_603752; Id: string;
          StartRecordIdentifier: string = ""; `type`: string = "SOA";
          identifier: string = ""; StartRecordType: string = ""; maxitems: string = "";
          StartRecordName: string = ""; name: string = ""; MaxItems: string = ""): Recallable =
  ## listResourceRecordSets
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to list.
  ##   StartRecordIdentifier: string
  ##                        : Pagination token
  ##   type: string
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   identifier: string
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  ##   StartRecordType: string
  ##                  : Pagination token
  ##   maxitems: string
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: string
  ##                  : Pagination token
  ##   name: string
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: string
  ##           : Pagination limit
  var path_603773 = newJObject()
  var query_603774 = newJObject()
  add(path_603773, "Id", newJString(Id))
  add(query_603774, "StartRecordIdentifier", newJString(StartRecordIdentifier))
  add(query_603774, "type", newJString(`type`))
  add(query_603774, "identifier", newJString(identifier))
  add(query_603774, "StartRecordType", newJString(StartRecordType))
  add(query_603774, "maxitems", newJString(maxitems))
  add(query_603774, "StartRecordName", newJString(StartRecordName))
  add(query_603774, "name", newJString(name))
  add(query_603774, "MaxItems", newJString(MaxItems))
  result = call_603772.call(path_603773, query_603774, nil, nil, nil)

var listResourceRecordSets* = Call_ListResourceRecordSets_603752(
    name: "listResourceRecordSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset",
    validator: validate_ListResourceRecordSets_603753, base: "/",
    url: url_ListResourceRecordSets_603754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResources_603775 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResources_603777(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListTagsForResources_603776(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resources.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceType` field"
  var valid_603778 = path.getOrDefault("ResourceType")
  valid_603778 = validateParameter(valid_603778, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_603778 != nil:
    section.add "ResourceType", valid_603778
  result.add "path", section
  section = newJObject()
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
  var valid_603779 = header.getOrDefault("X-Amz-Date")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Date", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Security-Token")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Security-Token", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Content-Sha256", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Algorithm")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Algorithm", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Signature")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Signature", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-SignedHeaders", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Credential")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Credential", valid_603785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603787: Call_ListTagsForResources_603775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_603787.validator(path, query, header, formData, body)
  let scheme = call_603787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603787.url(scheme.get, call_603787.host, call_603787.base,
                         call_603787.route, valid.getOrDefault("path"))
  result = hook(call_603787, url, valid)

proc call*(call_603788: Call_ListTagsForResources_603775; body: JsonNode;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResources
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceType: string (required)
  ##               : <p>The type of the resources.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   body: JObject (required)
  var path_603789 = newJObject()
  var body_603790 = newJObject()
  add(path_603789, "ResourceType", newJString(ResourceType))
  if body != nil:
    body_603790 = body
  result = call_603788.call(path_603789, nil, nil, nil, body_603790)

var listTagsForResources* = Call_ListTagsForResources_603775(
    name: "listTagsForResources", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/tags/{ResourceType}",
    validator: validate_ListTagsForResources_603776, base: "/",
    url: url_ListTagsForResources_603777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicies_603791 = ref object of OpenApiRestCall_602433
proc url_ListTrafficPolicies_603793(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTrafficPolicies_603792(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyid: JString
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  section = newJObject()
  var valid_603794 = query.getOrDefault("trafficpolicyid")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "trafficpolicyid", valid_603794
  var valid_603795 = query.getOrDefault("maxitems")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "maxitems", valid_603795
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
  var valid_603796 = header.getOrDefault("X-Amz-Date")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Date", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Security-Token")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Security-Token", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Content-Sha256", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Algorithm")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Algorithm", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Signature")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Signature", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-SignedHeaders", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Credential")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Credential", valid_603802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603803: Call_ListTrafficPolicies_603791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  let valid = call_603803.validator(path, query, header, formData, body)
  let scheme = call_603803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603803.url(scheme.get, call_603803.host, call_603803.base,
                         call_603803.route, valid.getOrDefault("path"))
  result = hook(call_603803, url, valid)

proc call*(call_603804: Call_ListTrafficPolicies_603791;
          trafficpolicyid: string = ""; maxitems: string = ""): Recallable =
  ## listTrafficPolicies
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ##   trafficpolicyid: string
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  var query_603805 = newJObject()
  add(query_603805, "trafficpolicyid", newJString(trafficpolicyid))
  add(query_603805, "maxitems", newJString(maxitems))
  result = call_603804.call(nil, query_603805, nil, nil, nil)

var listTrafficPolicies* = Call_ListTrafficPolicies_603791(
    name: "listTrafficPolicies", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicies",
    validator: validate_ListTrafficPolicies_603792, base: "/",
    url: url_ListTrafficPolicies_603793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstances_603806 = ref object of OpenApiRestCall_602433
proc url_ListTrafficPolicyInstances_603808(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTrafficPolicyInstances_603807(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_603809 = query.getOrDefault("trafficpolicyinstancename")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "trafficpolicyinstancename", valid_603809
  var valid_603810 = query.getOrDefault("maxitems")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "maxitems", valid_603810
  var valid_603811 = query.getOrDefault("trafficpolicyinstancetype")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = newJString("SOA"))
  if valid_603811 != nil:
    section.add "trafficpolicyinstancetype", valid_603811
  var valid_603812 = query.getOrDefault("hostedzoneid")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "hostedzoneid", valid_603812
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
  var valid_603813 = header.getOrDefault("X-Amz-Date")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Date", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Security-Token")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Security-Token", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Content-Sha256", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Algorithm")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Algorithm", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Signature")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Signature", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-SignedHeaders", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Credential")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Credential", valid_603819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603820: Call_ListTrafficPolicyInstances_603806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_603820.validator(path, query, header, formData, body)
  let scheme = call_603820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603820.url(scheme.get, call_603820.host, call_603820.base,
                         call_603820.route, valid.getOrDefault("path"))
  result = hook(call_603820, url, valid)

proc call*(call_603821: Call_ListTrafficPolicyInstances_603806;
          trafficpolicyinstancename: string = ""; maxitems: string = "";
          trafficpolicyinstancetype: string = "SOA"; hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstances
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_603822 = newJObject()
  add(query_603822, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_603822, "maxitems", newJString(maxitems))
  add(query_603822, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_603822, "hostedzoneid", newJString(hostedzoneid))
  result = call_603821.call(nil, query_603822, nil, nil, nil)

var listTrafficPolicyInstances* = Call_ListTrafficPolicyInstances_603806(
    name: "listTrafficPolicyInstances", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstances",
    validator: validate_ListTrafficPolicyInstances_603807, base: "/",
    url: url_ListTrafficPolicyInstances_603808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByHostedZone_603823 = ref object of OpenApiRestCall_602433
proc url_ListTrafficPolicyInstancesByHostedZone_603825(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTrafficPolicyInstancesByHostedZone_603824(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603826 = query.getOrDefault("id")
  valid_603826 = validateParameter(valid_603826, JString, required = true,
                                 default = nil)
  if valid_603826 != nil:
    section.add "id", valid_603826
  var valid_603827 = query.getOrDefault("trafficpolicyinstancename")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "trafficpolicyinstancename", valid_603827
  var valid_603828 = query.getOrDefault("maxitems")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "maxitems", valid_603828
  var valid_603829 = query.getOrDefault("trafficpolicyinstancetype")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = newJString("SOA"))
  if valid_603829 != nil:
    section.add "trafficpolicyinstancetype", valid_603829
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
  var valid_603830 = header.getOrDefault("X-Amz-Date")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Date", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-Security-Token")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Security-Token", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Content-Sha256", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-Algorithm")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Algorithm", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Signature")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Signature", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-SignedHeaders", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Credential")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Credential", valid_603836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603837: Call_ListTrafficPolicyInstancesByHostedZone_603823;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_603837.validator(path, query, header, formData, body)
  let scheme = call_603837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603837.url(scheme.get, call_603837.host, call_603837.base,
                         call_603837.route, valid.getOrDefault("path"))
  result = hook(call_603837, url, valid)

proc call*(call_603838: Call_ListTrafficPolicyInstancesByHostedZone_603823;
          id: string; trafficpolicyinstancename: string = ""; maxitems: string = "";
          trafficpolicyinstancetype: string = "SOA"): Recallable =
  ## listTrafficPolicyInstancesByHostedZone
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   id: string (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_603839 = newJObject()
  add(query_603839, "id", newJString(id))
  add(query_603839, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_603839, "maxitems", newJString(maxitems))
  add(query_603839, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  result = call_603838.call(nil, query_603839, nil, nil, nil)

var listTrafficPolicyInstancesByHostedZone* = Call_ListTrafficPolicyInstancesByHostedZone_603823(
    name: "listTrafficPolicyInstancesByHostedZone", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/hostedzone#id",
    validator: validate_ListTrafficPolicyInstancesByHostedZone_603824, base: "/",
    url: url_ListTrafficPolicyInstancesByHostedZone_603825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByPolicy_603840 = ref object of OpenApiRestCall_602433
proc url_ListTrafficPolicyInstancesByPolicy_603842(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTrafficPolicyInstancesByPolicy_603841(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: JInt (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603843 = query.getOrDefault("id")
  valid_603843 = validateParameter(valid_603843, JString, required = true,
                                 default = nil)
  if valid_603843 != nil:
    section.add "id", valid_603843
  var valid_603844 = query.getOrDefault("trafficpolicyinstancename")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "trafficpolicyinstancename", valid_603844
  var valid_603845 = query.getOrDefault("maxitems")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "maxitems", valid_603845
  var valid_603846 = query.getOrDefault("trafficpolicyinstancetype")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = newJString("SOA"))
  if valid_603846 != nil:
    section.add "trafficpolicyinstancetype", valid_603846
  var valid_603847 = query.getOrDefault("version")
  valid_603847 = validateParameter(valid_603847, JInt, required = true, default = nil)
  if valid_603847 != nil:
    section.add "version", valid_603847
  var valid_603848 = query.getOrDefault("hostedzoneid")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "hostedzoneid", valid_603848
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
  var valid_603849 = header.getOrDefault("X-Amz-Date")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Date", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Security-Token")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Security-Token", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Content-Sha256", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Algorithm")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Algorithm", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Signature")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Signature", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-SignedHeaders", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Credential")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Credential", valid_603855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603856: Call_ListTrafficPolicyInstancesByPolicy_603840;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_603856.validator(path, query, header, formData, body)
  let scheme = call_603856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603856.url(scheme.get, call_603856.host, call_603856.base,
                         call_603856.route, valid.getOrDefault("path"))
  result = hook(call_603856, url, valid)

proc call*(call_603857: Call_ListTrafficPolicyInstancesByPolicy_603840; id: string;
          version: int; trafficpolicyinstancename: string = ""; maxitems: string = "";
          trafficpolicyinstancetype: string = "SOA"; hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstancesByPolicy
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   id: string (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: int (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_603858 = newJObject()
  add(query_603858, "id", newJString(id))
  add(query_603858, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_603858, "maxitems", newJString(maxitems))
  add(query_603858, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_603858, "version", newJInt(version))
  add(query_603858, "hostedzoneid", newJString(hostedzoneid))
  result = call_603857.call(nil, query_603858, nil, nil, nil)

var listTrafficPolicyInstancesByPolicy* = Call_ListTrafficPolicyInstancesByPolicy_603840(
    name: "listTrafficPolicyInstancesByPolicy", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/trafficpolicy#id&version",
    validator: validate_ListTrafficPolicyInstancesByPolicy_603841, base: "/",
    url: url_ListTrafficPolicyInstancesByPolicy_603842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyVersions_603859 = ref object of OpenApiRestCall_602433
proc url_ListTrafficPolicyVersions_603861(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicies/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListTrafficPolicyVersions_603860(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Specify the value of <code>Id</code> of the traffic policy for which you want to list all versions.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603862 = path.getOrDefault("Id")
  valid_603862 = validateParameter(valid_603862, JString, required = true,
                                 default = nil)
  if valid_603862 != nil:
    section.add "Id", valid_603862
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyversion: JString
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  section = newJObject()
  var valid_603863 = query.getOrDefault("trafficpolicyversion")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "trafficpolicyversion", valid_603863
  var valid_603864 = query.getOrDefault("maxitems")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "maxitems", valid_603864
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
  var valid_603865 = header.getOrDefault("X-Amz-Date")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Date", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Security-Token")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Security-Token", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Content-Sha256", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Algorithm")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Algorithm", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Signature")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Signature", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-SignedHeaders", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Credential")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Credential", valid_603871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603872: Call_ListTrafficPolicyVersions_603859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ## 
  let valid = call_603872.validator(path, query, header, formData, body)
  let scheme = call_603872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603872.url(scheme.get, call_603872.host, call_603872.base,
                         call_603872.route, valid.getOrDefault("path"))
  result = hook(call_603872, url, valid)

proc call*(call_603873: Call_ListTrafficPolicyVersions_603859; Id: string;
          trafficpolicyversion: string = ""; maxitems: string = ""): Recallable =
  ## listTrafficPolicyVersions
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ##   Id: string (required)
  ##     : Specify the value of <code>Id</code> of the traffic policy for which you want to list all versions.
  ##   trafficpolicyversion: string
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  var path_603874 = newJObject()
  var query_603875 = newJObject()
  add(path_603874, "Id", newJString(Id))
  add(query_603875, "trafficpolicyversion", newJString(trafficpolicyversion))
  add(query_603875, "maxitems", newJString(maxitems))
  result = call_603873.call(path_603874, query_603875, nil, nil, nil)

var listTrafficPolicyVersions* = Call_ListTrafficPolicyVersions_603859(
    name: "listTrafficPolicyVersions", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicies/{Id}/versions",
    validator: validate_ListTrafficPolicyVersions_603860, base: "/",
    url: url_ListTrafficPolicyVersions_603861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestDNSAnswer_603876 = ref object of OpenApiRestCall_602433
proc url_TestDNSAnswer_603878(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TestDNSAnswer_603877(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resolverip: JString
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordname: JString (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   recordtype: JString (required)
  ##             : The type of the resource record set.
  ##   edns0clientsubnetmask: JString
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   edns0clientsubnetip: JString
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   hostedzoneid: JString (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  section = newJObject()
  var valid_603879 = query.getOrDefault("resolverip")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "resolverip", valid_603879
  assert query != nil,
        "query argument is necessary due to required `recordname` field"
  var valid_603880 = query.getOrDefault("recordname")
  valid_603880 = validateParameter(valid_603880, JString, required = true,
                                 default = nil)
  if valid_603880 != nil:
    section.add "recordname", valid_603880
  var valid_603881 = query.getOrDefault("recordtype")
  valid_603881 = validateParameter(valid_603881, JString, required = true,
                                 default = newJString("SOA"))
  if valid_603881 != nil:
    section.add "recordtype", valid_603881
  var valid_603882 = query.getOrDefault("edns0clientsubnetmask")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "edns0clientsubnetmask", valid_603882
  var valid_603883 = query.getOrDefault("edns0clientsubnetip")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "edns0clientsubnetip", valid_603883
  var valid_603884 = query.getOrDefault("hostedzoneid")
  valid_603884 = validateParameter(valid_603884, JString, required = true,
                                 default = nil)
  if valid_603884 != nil:
    section.add "hostedzoneid", valid_603884
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
  var valid_603885 = header.getOrDefault("X-Amz-Date")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Date", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Security-Token")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Security-Token", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Content-Sha256", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Algorithm")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Algorithm", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Signature")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Signature", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-SignedHeaders", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-Credential")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-Credential", valid_603891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603892: Call_TestDNSAnswer_603876; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  let valid = call_603892.validator(path, query, header, formData, body)
  let scheme = call_603892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603892.url(scheme.get, call_603892.host, call_603892.base,
                         call_603892.route, valid.getOrDefault("path"))
  result = hook(call_603892, url, valid)

proc call*(call_603893: Call_TestDNSAnswer_603876; recordname: string;
          hostedzoneid: string; resolverip: string = ""; recordtype: string = "SOA";
          edns0clientsubnetmask: string = ""; edns0clientsubnetip: string = ""): Recallable =
  ## testDNSAnswer
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ##   resolverip: string
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordname: string (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   recordtype: string (required)
  ##             : The type of the resource record set.
  ##   edns0clientsubnetmask: string
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   edns0clientsubnetip: string
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   hostedzoneid: string (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  var query_603894 = newJObject()
  add(query_603894, "resolverip", newJString(resolverip))
  add(query_603894, "recordname", newJString(recordname))
  add(query_603894, "recordtype", newJString(recordtype))
  add(query_603894, "edns0clientsubnetmask", newJString(edns0clientsubnetmask))
  add(query_603894, "edns0clientsubnetip", newJString(edns0clientsubnetip))
  add(query_603894, "hostedzoneid", newJString(hostedzoneid))
  result = call_603893.call(nil, query_603894, nil, nil, nil)

var testDNSAnswer* = Call_TestDNSAnswer_603876(name: "testDNSAnswer",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/testdnsanswer#hostedzoneid&recordname&recordtype",
    validator: validate_TestDNSAnswer_603877, base: "/", url: url_TestDNSAnswer_603878,
    schemes: {Scheme.Https, Scheme.Http})
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
